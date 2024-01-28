import Foundation
#if canImport(SwiftSyntax510)
import SwiftDiagnostics
#else
@preconcurrency import SwiftDiagnostics
#endif
import SwiftSyntax
import SwiftSyntaxMacros

@available(swift 5.9.2)
public struct CustomHashable: ExtensionMacro, MemberMacro {
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
        var isNSObjectSubclass = true

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
            case "NSObjectProtocol":
                isNSObjectSubclass = false
            default:
                throw ErrorDiagnosticMessage(
                    id: "unknown-protocol",
                    message: "Unknown protocol: '\(protocolType.trimmedDescription)'"
                )
            }
        }

        if isNSObjectSubclass {
            let hashPropertyExtension = ExtensionDeclSyntax(
                extendedType: type,
                memberBlock: MemberBlockSyntax(
                    members: try MemberBlockItemListSyntax(itemsBuilder: {
                        try expansionForHashProperty(
                            of: node,
                            providingMembersOf: declaration,
                            in: context
                        )
                    })
                )
            )
            let isEqualImplementationExtension = ExtensionDeclSyntax(
                extendedType: type,
                memberBlock: MemberBlockSyntax(
                    members: try MemberBlockItemListSyntax(itemsBuilder: {
                        try expansionForIsEqual(
                            of: node,
                            providingMembersOf: declaration,
                            in: context
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
                    members: try MemberBlockItemListSyntax(itemsBuilder: {
                        try expansionForHashable(
                            of: node,
                            providingMembersOf: declaration,
                            in: context
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
                            in: context
                        )
                    })
                )
            )
            protocolExtensions.append(hashableImplementationExtension)
            protocolExtensions.append(equatableImplementationExtension)
        }

        return protocolExtensions
    }

    private static func expansionForHashable(
        of node: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        in context: some MacroExpansionContext
    ) throws -> DeclSyntax {
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

        let memberList = declaration.memberBlock.members

        let propertyNames = memberList.flatMap({ member -> [TokenSyntax] in
            // is a property
            guard let variable = member.decl.as(VariableDeclSyntax.self) else {
                return []
            }

            let hasHashableKeyMacro = variable.attributes.contains(where: { element in
                let attributeName = element.as(AttributeSyntax.self)?.attributeName.as(IdentifierTypeSyntax.self)?.name.text
                 return attributeName == "HashableKey"
            })

            if hasHashableKeyMacro {
                return variable.bindings.compactMap({ binding in
                    binding
                        .as(PatternBindingSyntax.self)?
                        .pattern
                        .as(IdentifierPatternSyntax.self)?
                        .identifier
                })
            } else {
                return []
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
                for propertyToken in propertyNames {
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
        in context: some MacroExpansionContext
    ) throws -> DeclSyntax {
        guard let namedDeclaration = declaration as? NamedDeclSyntax else {
            throw InvalidDeclarationTypeError()
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

        let memberList = declaration.memberBlock.members

        let propertyNames = memberList.flatMap({ member -> [TokenSyntax] in
            // is a property
            guard let variable = member.decl.as(VariableDeclSyntax.self) else {
                return []
            }

            let hasHashableKeyMacro = variable.attributes.contains(where: { element in
                let attributeName = element.as(AttributeSyntax.self)?.attributeName.as(IdentifierTypeSyntax.self)?.name.text
                 return attributeName == "HashableKey"
            })

            if hasHashableKeyMacro {
                return variable.bindings.compactMap({ binding in
                    binding
                        .as(PatternBindingSyntax.self)?
                        .pattern
                        .as(IdentifierPatternSyntax.self)?
                        .identifier
                })
            } else {
                return []
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

        for propertyToken in propertyNames {
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
        in context: some MacroExpansionContext
    ) throws -> DeclSyntax {
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

        let memberList = declaration.memberBlock.members

        let propertyNames = memberList.flatMap({ member -> [TokenSyntax] in
            // is a property
            guard let variable = member.decl.as(VariableDeclSyntax.self) else {
                return []
            }

            let hasHashableKeyMacro = variable.attributes.contains(where: { element in
                let attributeName = element.as(AttributeSyntax.self)?.attributeName.as(IdentifierTypeSyntax.self)?.name.text
                 return attributeName == "HashableKey"
            })

            if hasHashableKeyMacro {
                return variable.bindings.compactMap({ binding in
                    binding
                        .as(PatternBindingSyntax.self)?
                        .pattern
                        .as(IdentifierPatternSyntax.self)?
                        .identifier
                })
            } else {
                return []
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

        for propertyToken in propertyNames {
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
        in context: some MacroExpansionContext
    ) throws -> DeclSyntax {
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

        let memberList = declaration.memberBlock.members

        let propertyNames = memberList.flatMap({ member -> [TokenSyntax] in
            // is a property
            guard let variable = member.decl.as(VariableDeclSyntax.self) else {
                return []
            }

            let hasHashableKeyMacro = variable.attributes.contains(where: { element in
                let attributeName = element.as(AttributeSyntax.self)?.attributeName.as(IdentifierTypeSyntax.self)?.name.text
                 return attributeName == "HashableKey"
            })

            if hasHashableKeyMacro {
                return variable.bindings.compactMap({ binding in
                    binding
                        .as(PatternBindingSyntax.self)?
                        .pattern
                        .as(IdentifierPatternSyntax.self)?
                        .identifier
                })
            } else {
                return []
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
                            VariableDeclSyntax(
                                bindingSpecifier: .keyword(.var),
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

                            for propertyToken in propertyNames {
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

private struct InvalidDeclarationTypeError: Error {}

private struct ErrorDiagnosticMessage: DiagnosticMessage, Error {
    let message: String
    let diagnosticID: MessageID
    let severity: DiagnosticSeverity

    init(id: String, message: String) {
        self.message = message
        diagnosticID = MessageID(domain: "uk.josephduffy.CustomHashable", id: id)
        severity = .error
    }
}
