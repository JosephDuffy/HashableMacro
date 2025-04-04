import Foundation
#if canImport(ObjectiveC)
import HashableMacroFoundation
#endif
import SwiftDiagnostics
import SwiftSyntax
import SwiftSyntaxMacros

public struct HashableMacro: ExtensionMacro {
    public static func expansion(
        of node: AttributeSyntax,
        attachedTo declaration: some DeclGroupSyntax,
        providingExtensionsOf type: some TypeSyntaxProtocol,
        conformingTo protocols: [TypeSyntax],
        in context: some MacroExpansionContext
    ) throws -> [ExtensionDeclSyntax] {
        guard !declaration.is(EnumDeclSyntax.self) else {
            throw HashableMacroDiagnosticMessage(
                id: "enum-not-supported",
                message: "'@Hashable' is not currently supported on enums.",
                severity: .error
            )
        }

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

        var allowEmptyImplementation: Bool?

        if let arguments = node.arguments?.as(LabeledExprListSyntax.self) {
            for argument in arguments {
                switch argument.label?.trimmed.text {
                case "allowEmptyImplementation":
                    guard let expression = argument.expression.as(BooleanLiteralExprSyntax.self) else { continue }
                    switch expression.literal.tokenKind {
                    case .keyword(.true):
                        allowEmptyImplementation = true
                    case .keyword(.false):
                        allowEmptyImplementation = false
                    default:
                        break
                    }
                #if canImport(ObjectiveC) && DEBUG
                case "_disableNSObjectSubclassSupport":
                    guard let expression = argument.expression.as(BooleanLiteralExprSyntax.self) else { continue }
                    switch expression.literal.tokenKind {
                    case .keyword(.true):
                        isNSObjectSubclass = false
                    default:
                        break
                    }
                #endif
                default:
                    break
                }
            }
        }

        let hashedVariableCandidates = declaration.memberBlock.members
            .compactMap { $0.decl.as(VariableDeclSyntax.self) }
            .filter(HashedMacro.isSupportedOnVariable(_:))
        var explicitlyHashedProperties: [TokenSyntax] = []
        var undecoratedProperties: [TokenSyntax] = []
        var notHashedAttributes: [AttributeSyntax] = []

        for variable in hashedVariableCandidates {
            let bindings = variable.bindings.compactMap({ binding in
                binding
                    .pattern
                    .as(IdentifierPatternSyntax.self)?
                    .identifier
            })
            lazy var isCalculated = variable.bindings.contains { binding in
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
                for attribute in variable.attributes {
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

        let propertiesToHash: [TokenSyntax]

        if !explicitlyHashedProperties.isEmpty {
            propertiesToHash = explicitlyHashedProperties
        } else if declaration.is(StructDeclSyntax.self) {
            propertiesToHash = undecoratedProperties
        } else if declaration.is(ClassDeclSyntax.self) {
            // We can't know if properties are added in a superclass, plus Swift
            // itself does not support this.
            throw HashableMacroDiagnosticMessage(
                id: "synthesised-properties-not-supported-class",
                message: "No properties marked with '@Hashed' were found. Synthesising Hashable conformance is not supported for classes.",
                severity: .error
            )
        } else if declaration.is(ActorDeclSyntax.self) {
            // Swift itself does not support this, probably for a good reason.
            throw HashableMacroDiagnosticMessage(
                id: "synthesised-properties-not-supported-actor",
                message: "No properties marked with '@Hashed' were found. Synthesising Hashable conformance is not supported for actors.",
                severity: .error
            )
        } else {
            throw HashableMacroDiagnosticMessage(
                id: "synthesised-properties-not-supported-unknown",
                message: "No properties marked with '@Hashed' were found. Synthesising Hashable conformance is not supported for this type.",
                severity: .error
            )
        }

        if propertiesToHash.isEmpty {
            switch allowEmptyImplementation {
            case .some(true):
                break
            case .some(false):
                throw HashableMacroDiagnosticMessage(
                    id: "no-properties-to-hash-disallowed",
                    message: "No hashable properties were found and 'allowEmptyImplementation' is 'false'.",
                    severity: .error
                )
            case nil:
                var arguments = node.arguments?.as(LabeledExprListSyntax.self) ?? LabeledExprListSyntax()
                arguments.addOrUpdateHashableArgument(
                    label: "allowEmptyImplementation",
                    expression: BooleanLiteralExprSyntax(booleanLiteral: true)
                )
                var fixedNode = node
                fixedNode.arguments = .argumentList(arguments)
                fixedNode.leftParen = .leftParenToken()
                fixedNode.rightParen = .rightParenToken()
                let diagnostic = Diagnostic(
                    node: node,
                    message: HashableMacroDiagnosticMessage(
                        id: "no-properties-to-hash",
                        message: "No hashable properties were found. All instances will be equal to each other.",
                        severity: .warning
                    ),
                    fixIt: FixIt(
                        message: HashableMacroFixItMessage(
                            id: "redundant-not-hashed",
                            message: "Add 'allowEmptyImplementation: true' to silence this warning."
                        ),
                        changes: [
                            FixIt.Change.replace(
                                oldNode: Syntax(node),
                                newNode: Syntax(fixedNode)
                            )
                        ]
                    )
                )
                context.diagnose(diagnostic)
            }
        }

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
            guard let classDeclaration = declaration.as(ClassDeclSyntax.self) else {
                throw HashableMacroDiagnosticMessage(
                    id: "nsobject-subclass-not-class",
                    message: "This type conforms to 'NSObjectProtocol' but is not a class",
                    severity: .error
                )
            }

            var isEqualToTypeFunctionName: IsEqualToTypeFunctionNameGeneration = .automatic

            if let arguments = node.arguments?.as(LabeledExprListSyntax.self) {
                for argument in arguments {
                    switch argument.label?.trimmedDescription {
                    case "isEqualToTypeFunctionName":
                        if let expression = argument.expression.as(MemberAccessExprSyntax.self) {
                            switch expression.declName.baseName.tokenKind {
                            case .identifier("automatic"):
                                isEqualToTypeFunctionName = .automatic
                            default:
                                throw HashableMacroDiagnosticMessage(
                                    id: "unknown-isEqualToTypeFunctionName-name",
                                    message: "'\(expression.declName.baseName)' is not a known value for `IsEqualToTypeFunctionNameGeneration`.",
                                    severity: .error
                                )
                            }
                        } else if
                            let functionExpression = argument
                                .expression
                                .as(FunctionCallExprSyntax.self),
                            let memberAccessExpression = functionExpression
                                .calledExpression
                                .as(MemberAccessExprSyntax.self)
                        {
                            switch memberAccessExpression.declName.baseName.tokenKind {
                            case .identifier("custom"):
                                guard functionExpression.arguments.count == 1 else {
                                    throw HashableMacroDiagnosticMessage(
                                        id: "invalid-isEqualToTypeFunctionName-argument",
                                        message: "Only 1 argument is supported for 'custom'.",
                                        severity: .error
                                    )
                                }
                                let nameArgument = functionExpression.arguments.first!

                                guard let stringExpression = nameArgument.expression.as(StringLiteralExprSyntax.self) else {
                                    throw HashableMacroDiagnosticMessage(
                                        id: "invalid-isEqualToTypeFunctionName-custom-argument",
                                        message: "Only option for 'custom' must be a string.",
                                        severity: .error
                                    )
                                }

                                let customName = "\(stringExpression.segments)"

                                if !customName.hasSuffix(":") {
                                    var newArgument = argument
                                    var functionExpression = functionExpression
                                    functionExpression.arguments[functionExpression.arguments.indices.first!].expression = ExprSyntax(StringLiteralExprSyntax(content: customName + ":"))
                                    newArgument.expression = ExprSyntax(functionExpression)

                                    let diagnostic = Diagnostic(
                                        node: Syntax(node),
                                        message: HashableMacroDiagnosticMessage(
                                            id: "missing-colon-for-custom-name",
                                            message: "Custom Objective-C function name must end with a colon.",
                                            severity: .error
                                        ),
                                        fixIt: FixIt(
                                            message: HashableMacroFixItMessage(
                                                id: "add-missing-colon-to-custom-name",
                                                message: "Add ':'"
                                            ),
                                            changes: [
                                                FixIt.Change.replace(
                                                    oldNode: Syntax(argument),
                                                    newNode: Syntax(newArgument)
                                                )
                                            ]
                                        )
                                    )
                                    context.diagnose(diagnostic)
                                }

                                isEqualToTypeFunctionName = .custom(customName)
                            default:
                                throw HashableMacroDiagnosticMessage(
                                    id: "unknown-isEqualToTypeFunctionName-name",
                                    message: "'\(memberAccessExpression.declName.baseName)' is not a known value for `IsEqualToTypeFunctionNameGeneration`",
                                    severity: .error
                                )
                            }

                        } else {
                            throw HashableMacroDiagnosticMessage(
                                id: "unknown-isEqualToTypeFunctionName-type",
                                message: "'isEqualToTypeFunctionName' parameter was not of the expected type",
                                severity: .error
                            )
                        }
                    default:
                        break
                    }
                }
            }

            let hashPropertyExtension = ExtensionDeclSyntax(
                extendedType: type,
                memberBlock: MemberBlockSyntax(
                    members: MemberBlockItemListSyntax(itemsBuilder: {
                        expansionForHashProperty(
                            of: node,
                            providingMembersOf: declaration,
                            in: context,
                            propertiesToHash: propertiesToHash
                        )
                    })
                )
            )
            let isEqualImplementationExtension = ExtensionDeclSyntax(
                extendedType: type,
                memberBlock: MemberBlockSyntax(
                    members: MemberBlockItemListSyntax(
                        expansionForIsEqual(
                            of: node,
                            providingMembersOf: classDeclaration,
                            in: context,
                            propertiesToHash: propertiesToHash,
                            isEqualToTypeFunctionName: isEqualToTypeFunctionName
                        ).map { MemberBlockItemSyntax(decl: $0) }
                    )
                )
            )
            protocolExtensions.append(hashPropertyExtension)
            protocolExtensions.append(isEqualImplementationExtension)
            return protocolExtensions
        }
        #endif
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

        return protocolExtensions
    }
}
