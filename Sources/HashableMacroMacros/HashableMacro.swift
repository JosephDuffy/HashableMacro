import Foundation
#if canImport(SwiftSyntax510)
import SwiftDiagnostics
#else
@preconcurrency import SwiftDiagnostics
#endif
import SwiftSyntax
import SwiftSyntaxMacros

@available(swift 5.9.2)
public struct HashableMacro: ExtensionMacro {
    public static func expansion(
        of node: AttributeSyntax,
        attachedTo declaration: some DeclGroupSyntax,
        providingExtensionsOf type: some TypeSyntaxProtocol,
        conformingTo protocols: [TypeSyntax],
        in context: some MacroExpansionContext
    ) throws -> [ExtensionDeclSyntax] {
        // The macro declares that it can add `NSObjectProtocol`, but this is
        // used to check whether the compiler asks for it to be added. If the
        // macro is asked to add `NSObjectProtocol` conformance then we know
        // this is not an `NSObject` subclass.
        #if canImport(ObjectiveC)
        var isNSObjectSubclass = true
        #endif

        var protocolExtensions: [ExtensionDeclSyntax] = []

        for protocolType in protocols {
            switch protocolType.trimmedDescription {
            case "Hashable", "Equatable":
                let protocolExtension = ExtensionDeclSyntax(
                    extendedType: type,
                    inheritanceClause: InheritanceClauseSyntax(
                        inheritedTypes: InheritedTypeListSyntax(itemsBuilder: {
                            InheritedTypeSyntax(
                                type: protocolType
                            )
                        })
                    ),
                    memberBlock: MemberBlockSyntax(members: "")
                )
                protocolExtensions.append(protocolExtension)
            #if canImport(ObjectiveC)
            case "NSObjectProtocol":
                isNSObjectSubclass = false
            #endif
            default:
                throw HashableMacroDiagnosticMessage(
                    id: "unknown-protocol",
                    message: "Unknown protocol: '\(protocolType.trimmedDescription)'",
                    severity: .error
                )
            }
        }

        let properties = declaration.memberBlock.members.compactMap({ $0.decl.as(VariableDeclSyntax.self) })
        var explicitlyHashedProperties: [TokenSyntax] = []
        var undecoratedProperties: [TokenSyntax] = []
        var notHashedAttributes: [AttributeSyntax] = []

        for property in properties {
            let bindings = property.bindings.compactMap({ binding in
                binding
                    .pattern
                    .as(IdentifierPatternSyntax.self)?
                    .identifier
            })
            lazy var isCalculated = property.bindings.contains { binding in
                guard let accessorBlock = binding.accessorBlock else { return false }
                switch accessorBlock.accessors {
                case .getter:
                    return true
                case .accessors(let accessors):
                    for accessor in accessors {
                        switch accessor.accessorSpecifier.tokenKind {
                        case .keyword(.get):
                            return true
                        default:
                            break
                        }
                    }
                }
                return false
            }

            func attribute(named macroName: String) -> AttributeSyntax? {
                for attribute in property.attributes {
                    guard let attribute = attribute.as(AttributeSyntax.self) else { continue }
                    let identifier = attribute
                        .attributeName
                        .as(IdentifierTypeSyntax.self)
                    if identifier?.name.tokenKind == .identifier(macroName) {
                        return attribute
                    }
                }

                return nil
            }

            if attribute(named: "Hashed") != nil {
                explicitlyHashedProperties.append(contentsOf: bindings)
            } else if let notHashedAttribute = attribute(named: "NotHashed") {
                notHashedAttributes.append(notHashedAttribute)
            } else if !isCalculated {
                undecoratedProperties.append(contentsOf: bindings)
            }
        }

        if !explicitlyHashedProperties.isEmpty {
            for notHashedAttribute in notHashedAttributes {
                let fixIt = FixIt(
                    message: HashableMacroFixItMessage(
                        id: "redundant-not-hashed",
                        message: "Remove @NotHashed"
                    ),
                    changes: [
                        FixIt.Change.replace(
                            oldNode: Syntax(notHashedAttribute),
                            newNode: Syntax("" as DeclSyntax)
                        )
                    ]
                )
                let diagnostic = Diagnostic(
                    node: Syntax(notHashedAttribute),
                    message: HashableMacroDiagnosticMessage(
                        id: "redundant-not-hashed",
                        message: "The @NotHashed macro is redundant when 1 or more properties are decorated @Hashed. It will be ignored",
                        severity: .warning
                    ),
                    fixIt: fixIt
                )
                context.diagnose(diagnostic)
            }
        }

        let propertiesToHash = !explicitlyHashedProperties.isEmpty ? explicitlyHashedProperties : undecoratedProperties

        #if canImport(ObjectiveC)
        #if DEBUG
        // The testing library does not process the required protocols and
        // passes and empty array for `protocols`. This means that the macro
        // assumes that the type conforms to `NSObjectProtocol`. This argument
        // cannot be passed in code but it can be passed when the input code is
        // written as a string.
        if let arguments = node.arguments?.as(LabeledExprListSyntax.self) {
            for argument in arguments {
                switch argument.label?.trimmed.text {
                case "_disableNSObjectSubclassSupport":
                    guard let expression = argument.expression.as(BooleanLiteralExprSyntax.self) else { continue }
                    switch expression.literal.tokenKind {
                    case .keyword(.true):
                        isNSObjectSubclass = false
                    default:
                        break
                    }
                default:
                    break
                }
            }
        }
        #endif
        if isNSObjectSubclass {
            guard let namedDeclaration = declaration as? ClassDeclSyntax else {
                throw HashableMacroDiagnosticMessage(
                    id: "nsobject-subclass-not-class",
                    message: "This type conforms to 'NSObjectProtocol' but is not a class",
                    severity: .error
                )
            }

            var nsObjectSubclassBehaviour: NSObjectSubclassBehaviour = .callSuperUnlessDirectSubclass

            if let arguments = node.arguments?.as(LabeledExprListSyntax.self) {
                for argument in arguments {
                    switch argument.label?.trimmedDescription {
                    case "nsObjectSubclassBehaviour":
                        guard let expression = argument.expression.as(MemberAccessExprSyntax.self) else {
                            throw HashableMacroDiagnosticMessage(
                                id: "unknown-nsObjectSubclassBehaviour-type",
                                message: "'nsObjectSubclassBehaviour' parameter was not of the expected type",
                                severity: .error
                            )
                        }
                        switch expression.declName.baseName.tokenKind {
                        case .identifier("neverCallSuper"):
                            nsObjectSubclassBehaviour = .neverCallSuper
                        case .identifier("callSuperUnlessDirectSubclass"):
                            nsObjectSubclassBehaviour = .callSuperUnlessDirectSubclass
                        case .identifier("alwaysCallSuper"):
                            nsObjectSubclassBehaviour = .alwaysCallSuper
                        default:
                            throw HashableMacroDiagnosticMessage(
                                id: "unknown-nsObjectSubclassBehaviour-name",
                                message: "'\(expression.declName.baseName)' is not a known value for `NSObjectSubclassBehaviour`; \(expression.declName.baseName.debugDescription))",
                                severity: .error
                            )
                        }
                    default:
                        break
                    }
                }
            }

            let doIncorporateSuper: Bool

            switch nsObjectSubclassBehaviour {
            case .neverCallSuper:
                doIncorporateSuper = false
            case .callSuperUnlessDirectSubclass:
                doIncorporateSuper = namedDeclaration.inheritanceClause?.inheritedTypes.first?.type.trimmedDescription != "NSObject"
            case .alwaysCallSuper:
                doIncorporateSuper = true
            }

            let hashPropertyExtension = ExtensionDeclSyntax(
                extendedType: type,
                memberBlock: MemberBlockSyntax(
                    members: MemberBlockItemListSyntax(itemsBuilder: {
                        expansionForHashProperty(
                            of: node,
                            providingMembersOf: declaration,
                            in: context,
                            propertiesToHash: propertiesToHash,
                            doIncorporateSuper: doIncorporateSuper
                        )
                    })
                )
            )
            let isEqualImplementationExtension = ExtensionDeclSyntax(
                extendedType: type,
                memberBlock: MemberBlockSyntax(
                    members: MemberBlockItemListSyntax(itemsBuilder: {
                        expansionForIsEqual(
                            of: node,
                            providingMembersOf: declaration,
                            in: context,
                            propertiesToHash: propertiesToHash,
                            doIncorporateSuper: doIncorporateSuper
                        )
                    })
                )
            )
            protocolExtensions.append(hashPropertyExtension)
            protocolExtensions.append(isEqualImplementationExtension)
        } else {
            let hashableImplementationExtension = ExtensionDeclSyntax(
                extendedType: type,
                memberBlock: MemberBlockSyntax(
                    members: MemberBlockItemListSyntax(itemsBuilder: {
                        expansionForHashable(
                            of: node,
                            providingMembersOf: declaration,
                            in: context,
                            propertiesToHash: propertiesToHash
                        )
                    })
                )
            )
            let equatableImplementationExtension = ExtensionDeclSyntax(
                extendedType: type,
                memberBlock: MemberBlockSyntax(
                    members: try MemberBlockItemListSyntax(itemsBuilder: {
                        try expansionForEquals(
                            of: node,
                            providingMembersOf: declaration,
                            in: context,
                            propertiesToHash: propertiesToHash
                        )
                    })
                )
            )
            protocolExtensions.append(hashableImplementationExtension)
            protocolExtensions.append(equatableImplementationExtension)
        }
        #else
        let hashableImplementationExtension = ExtensionDeclSyntax(
            extendedType: type,
            memberBlock: MemberBlockSyntax(
                members: MemberBlockItemListSyntax(itemsBuilder: {
                    expansionForHashable(
                        of: node,
                        providingMembersOf: declaration,
                        in: context,
                        propertiesToHash: propertiesToHash
                    )
                })
            )
        )
        let equatableImplementationExtension = ExtensionDeclSyntax(
            extendedType: type,
            memberBlock: MemberBlockSyntax(
                members: try MemberBlockItemListSyntax(itemsBuilder: {
                    try expansionForEquals(
                        of: node,
                        providingMembersOf: declaration,
                        in: context,
                        propertiesToHash: propertiesToHash
                    )
                })
            )
        )
        protocolExtensions.append(hashableImplementationExtension)
        protocolExtensions.append(equatableImplementationExtension)
        #endif

        return protocolExtensions
    }

    private static func expansionForHashable(
        of node: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        in context: some MacroExpansionContext,
        propertiesToHash: [TokenSyntax]
    ) -> DeclSyntax {
        var finalHashInto = true

        if let arguments = node.arguments?.as(LabeledExprListSyntax.self) {
            for argument in arguments {
                switch argument.label?.trimmed.text {
                case "finalHashInto":
                    guard let expression = argument.expression.as(BooleanLiteralExprSyntax.self) else { continue }
                    switch expression.literal.tokenKind {
                    case .keyword(.true):
                        finalHashInto = true
                    case .keyword(.false):
                        finalHashInto = false
                    default:
                        break
                    }
                default:
                    break
                }
            }
        }

        let baseModifiers = declaration.modifiers.filter({ modifier in
            switch (modifier.name.tokenKind) {
            case .keyword(.public):
                return true
            case .keyword(.internal):
                return true
            case .keyword(.fileprivate):
                return true
            case .keyword(.private):
                // The added functions should never be private
                return false
            default:
                return false
            }
        })

        var hashFunctionModifiers = baseModifiers
        if finalHashInto, declaration.is(ClassDeclSyntax.self) {
            hashFunctionModifiers.append(
                DeclModifierSyntax(name: .keyword(.final))
            )
        }

        let hashFunctionSignature = FunctionSignatureSyntax(
            parameterClause: FunctionParameterClauseSyntax(
                parameters: [
                    FunctionParameterSyntax(
                        firstName: .identifier("into"),
                        secondName: .identifier("hasher"),
                        type: AttributedTypeSyntax(
                            specifier: .keyword(.inout),
                            baseType: TypeSyntax(stringLiteral: "Hasher")
                        )
                    ),
                ]
            )
        )

        let hashFunctionBody = CodeBlockSyntax(
            statements: CodeBlockItemListSyntax(itemsBuilder: {
                for propertyToken in propertiesToHash {
                    FunctionCallExprSyntax(
                        callee: MemberAccessExprSyntax(
                            base: DeclReferenceExprSyntax(baseName: "hasher"),
                            name: .identifier("combine")
                        ),
                        argumentList: {
                            LabeledExprSyntax(
                                expression: MemberAccessExprSyntax(
                                    base: DeclReferenceExprSyntax(baseName: .keyword(.`self`)),
                                    name: propertyToken
                                )
                            )
                        }
                    )
                }
            })
        )

        let hashFunction = FunctionDeclSyntax(
            modifiers: hashFunctionModifiers,
            name: .identifier("hash"),
            signature: hashFunctionSignature,
            body: hashFunctionBody
        )

        return DeclSyntax(hashFunction)
    }

    private static func expansionForEquals(
        of node: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        in context: some MacroExpansionContext,
        propertiesToHash: [TokenSyntax]
    ) throws -> DeclSyntax {
        guard let namedDeclaration = declaration as? NamedDeclSyntax else {
            throw HashableMacroDiagnosticMessage(
                id: "not-named-declaration",
                message: "'@Hashable' can only be applied to named declarations",
                severity: .error
            )
        }

        let baseModifiers = declaration.modifiers.filter({ modifier in
            switch (modifier.name.tokenKind) {
            case .keyword(.public):
                return true
            case .keyword(.internal):
                return true
            case .keyword(.fileprivate):
                return true
            case .keyword(.private):
                // The added functions should never be private
                return false
            default:
                return false
            }
        })

        let equalsFunctionSignature = FunctionSignatureSyntax(
            parameterClause: FunctionParameterClauseSyntax(
                parameters: [
                    FunctionParameterSyntax(
                        firstName: .identifier("lhs"),
                        type: TypeSyntax(stringLiteral: namedDeclaration.name.text),
                        trailingComma: .commaToken()
                    ),
                    FunctionParameterSyntax(
                        firstName: .identifier("rhs"),
                        type: TypeSyntax(stringLiteral: namedDeclaration.name.text)
                    ),
                ]
            ),
            returnClause: ReturnClauseSyntax(
                type: IdentifierTypeSyntax(name: .identifier("Bool"))
            )
        )

        var comparisons: InfixOperatorExprSyntax?

        for propertyToken in propertiesToHash {
            let comparison = InfixOperatorExprSyntax(
                leftOperand: MemberAccessExprSyntax(
                    base: DeclReferenceExprSyntax(
                        baseName: .identifier("lhs")
                    ),
                    declName: DeclReferenceExprSyntax(
                        baseName: propertyToken
                    )
                ),
                operator: BinaryOperatorExprSyntax(
                    operator: .binaryOperator("==")
                ),
                rightOperand: MemberAccessExprSyntax(
                    base: DeclReferenceExprSyntax(
                        baseName: .identifier("rhs")
                    ),
                    declName: DeclReferenceExprSyntax(
                        baseName: propertyToken
                    )
                )
            )

            if let existingComparisons = comparisons {
                comparisons = InfixOperatorExprSyntax(
                    leftOperand: existingComparisons,
                    operator: BinaryOperatorExprSyntax(
                        leadingTrivia: .newline.appending(Trivia.spaces(8)),
                        operator: .binaryOperator("&&")
                    ),
                    rightOperand: comparison
                )
            } else {
                comparisons = comparison
            }
        }

        let equalsBody = CodeBlockSyntax(
            statements: CodeBlockItemListSyntax(itemsBuilder: {
                if let comparisons {
                    ReturnStmtSyntax(
                        leadingTrivia: .spaces(4),
                        expression: comparisons
                    )
                } else {
                    ReturnStmtSyntax(
                        leadingTrivia: .spaces(4),
                        expression: BooleanLiteralExprSyntax(booleanLiteral: true)
                    )
                }
            })
        )

        var equalsFunctionModifiers = baseModifiers
        equalsFunctionModifiers.append(
            DeclModifierSyntax(name: .keyword(.static))
        )

        let equalsFunction = FunctionDeclSyntax(
            modifiers: equalsFunctionModifiers,
            name: .identifier("=="),
            signature: equalsFunctionSignature,
            body: equalsBody
        )

        return DeclSyntax(equalsFunction)
    }

    private static func expansionForIsEqual(
        of node: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        in context: some MacroExpansionContext,
        propertiesToHash: [TokenSyntax],
        doIncorporateSuper: Bool
    ) -> DeclSyntax {
        let baseModifiers = declaration.modifiers.filter({ modifier in
            switch (modifier.name.tokenKind) {
            case .keyword(.public):
                return true
            case .keyword(.internal):
                return true
            case .keyword(.fileprivate):
                return true
            case .keyword(.private):
                // The added functions should never be private
                return false
            default:
                return false
            }
        })

        let isEqualFunctionSignature = FunctionSignatureSyntax(
            parameterClause: FunctionParameterClauseSyntax(
                parameters: [
                    FunctionParameterSyntax(
                        firstName: .identifier("_"),
                        secondName: .identifier("object"),
                        type: OptionalTypeSyntax(wrappedType: "Any" as TypeSyntax)
                    )
                ]
            ),
            returnClause: ReturnClauseSyntax(
                type: IdentifierTypeSyntax(name: .identifier("Bool"))
            )
        )

        var comparisons: InfixOperatorExprSyntax?

        for propertyToken in propertiesToHash {
            let comparison = InfixOperatorExprSyntax(
                leftOperand: MemberAccessExprSyntax(
                    base: DeclReferenceExprSyntax(
                        baseName: .keyword(.`self`)
                    ),
                    declName: DeclReferenceExprSyntax(
                        baseName: propertyToken
                    )
                ),
                operator: BinaryOperatorExprSyntax(
                    operator: .binaryOperator("==")
                ),
                rightOperand: MemberAccessExprSyntax(
                    base: DeclReferenceExprSyntax(
                        baseName: .identifier("object")
                    ),
                    declName: DeclReferenceExprSyntax(
                        baseName: propertyToken
                    )
                )
            )

            if let existingComparisons = comparisons {
                comparisons = InfixOperatorExprSyntax(
                    leftOperand: existingComparisons,
                    operator: BinaryOperatorExprSyntax(
                        leadingTrivia: .newline.appending(Trivia.spaces(8)),
                        operator: .binaryOperator("&&")
                    ),
                    rightOperand: comparison
                )
            } else {
                comparisons = comparison
            }
        }

        let isEqualBody = CodeBlockSyntax(
            statements: CodeBlockItemListSyntax(itemsBuilder: {
                GuardStmtSyntax(
                    conditions: ConditionElementListSyntax {
                        OptionalBindingConditionSyntax(
                            bindingSpecifier: .keyword(.let),
                            pattern: IdentifierPatternSyntax(
                                identifier: .identifier("object")
                            )
                        )
                    },
                    bodyBuilder: {
                        ReturnStmtSyntax(
                            leadingTrivia: .spaces(4),
                            expression: BooleanLiteralExprSyntax(booleanLiteral: false)
                        )
                    }
                )
                GuardStmtSyntax(
                    conditions: ConditionElementListSyntax {
                        InfixOperatorExprSyntax(
                            leftOperand: FunctionCallExprSyntax(
                                calledExpression: DeclReferenceExprSyntax(
                                    baseName: .identifier("type")
                                ),
                                leftParen: .leftParenToken(),
                                arguments: [
                                    LabeledExprSyntax(
                                        label: "of",
                                        expression: DeclReferenceExprSyntax(
                                            baseName: .keyword(.`self`)
                                        )
                                    )
                                ],
                                rightParen: .rightParenToken()
                            ),
                            operator: BinaryOperatorExprSyntax(
                                operator: .binaryOperator("==")
                            ),
                            rightOperand: FunctionCallExprSyntax(
                                calledExpression: DeclReferenceExprSyntax(
                                    baseName: .identifier("type")
                                ),
                                leftParen: .leftParenToken(),
                                arguments: [
                                    LabeledExprSyntax(
                                        label: "of",
                                        expression: DeclReferenceExprSyntax(
                                            baseName: .identifier("object")
                                        )
                                    )
                                ],
                                rightParen: .rightParenToken()
                            )
                        )
                    },
                    bodyBuilder: {
                        ReturnStmtSyntax(
                            leadingTrivia: .spaces(4),
                            expression: BooleanLiteralExprSyntax(booleanLiteral: false)
                        )
                    }
                )

                if doIncorporateSuper {
                    GuardStmtSyntax(
                        conditions: ConditionElementListSyntax {
                            FunctionCallExprSyntax(
                                calledExpression: MemberAccessExprSyntax(
                                    base: SuperExprSyntax(),
                                    name: .identifier("isEqual")
                                ),
                                leftParen: .leftParenToken(),
                                arguments: [
                                    LabeledExprSyntax(
                                        expression: DeclReferenceExprSyntax(
                                            baseName: .identifier("object")
                                        )
                                    )
                                ],
                                rightParen: .rightParenToken()
                            )
                        },
                        bodyBuilder: {
                            ReturnStmtSyntax(
                                leadingTrivia: .spaces(4),
                                expression: BooleanLiteralExprSyntax(booleanLiteral: false)
                            )
                        }
                    )
                }
                if let comparisons {
                    GuardStmtSyntax(
                        conditions: ConditionElementListSyntax {
                            OptionalBindingConditionSyntax(
                                bindingSpecifier: .keyword(.let),
                                pattern: IdentifierPatternSyntax(
                                    identifier: .identifier("object")
                                ),
                                initializer: InitializerClauseSyntax(
                                    value: AsExprSyntax(
                                        expression: DeclReferenceExprSyntax(baseName: "object"),
                                        questionOrExclamationMark: .postfixQuestionMarkToken(),
                                        type: IdentifierTypeSyntax(
                                            name: .keyword(.`Self`)
                                        )
                                    )
                                )
                            )
                        },
                        bodyBuilder: {
                            ReturnStmtSyntax(
                                leadingTrivia: .spaces(4),
                                expression: BooleanLiteralExprSyntax(booleanLiteral: false)
                            )
                        }
                    )
                    ReturnStmtSyntax(
                        expression: comparisons
                    )
                } else {
                    ReturnStmtSyntax(
                        expression: BooleanLiteralExprSyntax(booleanLiteral: true)
                    )
                }
            })
        )

        var equalsFunctionModifiers = baseModifiers
        equalsFunctionModifiers.append(
            DeclModifierSyntax(name: .keyword(.override))
        )

        let equalsFunction = FunctionDeclSyntax(
            modifiers: equalsFunctionModifiers,
            name: .identifier("isEqual"),
            signature: isEqualFunctionSignature,
            body: isEqualBody
        )

        return DeclSyntax(equalsFunction)
    }

    private static func expansionForHashProperty(
        of node: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        in context: some MacroExpansionContext,
        propertiesToHash: [TokenSyntax],
        doIncorporateSuper: Bool
    ) -> DeclSyntax {
        let baseModifiers = declaration.modifiers.filter({ modifier in
            switch (modifier.name.tokenKind) {
            case .keyword(.public):
                return true
            case .keyword(.internal):
                return true
            case .keyword(.fileprivate):
                return true
            case .keyword(.private):
                // The added functions should never be private
                return false
            default:
                return false
            }
        })

        var hashPropertyModifiers = baseModifiers
        hashPropertyModifiers.append(
            DeclModifierSyntax(name: .keyword(.override))
        )

        let hashPropertyDeclaration = VariableDeclSyntax(
            modifiers: hashPropertyModifiers,
            bindingSpecifier: .keyword(.var),
            bindings: PatternBindingListSyntax([
                PatternBindingSyntax(
                    pattern: IdentifierPatternSyntax(identifier: .identifier("hash")),
                    typeAnnotation: TypeAnnotationSyntax(
                        type: IdentifierTypeSyntax(name: .identifier("Int"))
                    ),
                    accessorBlock: AccessorBlockSyntax(
                        accessors: .getter(CodeBlockItemListSyntax(itemsBuilder: {
                            let havePropertiesToHash = doIncorporateSuper || !propertiesToHash.isEmpty

                            VariableDeclSyntax(
                                bindingSpecifier: .keyword(havePropertiesToHash ? .var : .let),
                                bindings: PatternBindingListSyntax([
                                    PatternBindingSyntax(
                                        pattern: IdentifierPatternSyntax(identifier: .identifier("hasher")),
                                        initializer: InitializerClauseSyntax(
                                            value: FunctionCallExprSyntax(
                                                calledExpression: DeclReferenceExprSyntax(
                                                    baseName: TokenSyntax.identifier("Hasher")
                                                ),
                                                leftParen: .leftParenToken(),
                                                arguments: [],
                                                rightParen: .rightParenToken()
                                            )
                                        )
                                    )
                                ])
                            )

                            if doIncorporateSuper {
                                FunctionCallExprSyntax(
                                    callee: MemberAccessExprSyntax(
                                        base: DeclReferenceExprSyntax(baseName: "hasher"),
                                        name: .identifier("combine")
                                    ),
                                    argumentList: {
                                        LabeledExprSyntax(
                                            expression: MemberAccessExprSyntax(
                                                base: DeclReferenceExprSyntax(baseName: .keyword(.super)),
                                                name: .identifier("hash")
                                            )
                                        )
                                    }
                                )
                            }

                            for propertyToken in propertiesToHash {
                                FunctionCallExprSyntax(
                                    callee: MemberAccessExprSyntax(
                                        base: DeclReferenceExprSyntax(baseName: "hasher"),
                                        name: .identifier("combine")
                                    ),
                                    argumentList: {
                                        LabeledExprSyntax(
                                            expression: MemberAccessExprSyntax(
                                                base: DeclReferenceExprSyntax(baseName: .keyword(.`self`)),
                                                name: propertyToken
                                            )
                                        )
                                    }
                                )
                            }

                            ReturnStmtSyntax(
                                expression: FunctionCallExprSyntax(
                                    calledExpression: MemberAccessExprSyntax(
                                        base: DeclReferenceExprSyntax(baseName: .identifier("hasher")),
                                        name: .identifier("finalize")
                                    ),
                                    leftParen: .leftParenToken(),
                                    arguments: [],
                                    rightParen: .rightParenToken()
                                )
                            )
                        }))
                    )
                )
            ])
        )

        return DeclSyntax(hashPropertyDeclaration)
    }
}

private struct HashableMacroDiagnosticMessage: DiagnosticMessage, Error {
    let message: String
    let diagnosticID: MessageID
    let severity: DiagnosticSeverity

    init(id: String, message: String, severity: DiagnosticSeverity) {
        self.message = message
        diagnosticID = MessageID(domain: "uk.josephduffy.HashableMacro", id: id)
        self.severity = severity
    }
}

private struct HashableMacroFixItMessage: FixItMessage {
    let fixItID: MessageID
    let message: String

    init(id: String, message: String) {
        fixItID = MessageID(domain: "uk.josephduffy.HashableMacro", id: id)
        self.message = message
    }
}
