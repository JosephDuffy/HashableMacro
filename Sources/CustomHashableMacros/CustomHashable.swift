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
        try protocols.map { protocolType in
            switch protocolType.trimmedDescription {
            case "Hashable", "Equatable":
                return ExtensionDeclSyntax(
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
            default:
                throw ErrorDiagnosticMessage(
                    id: "unknown-protocol",
                    message: "Unknown protocol: '\(protocolType.trimmedDescription)'"
                )
            }
        }
    }

    public static func expansion(
        of node: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        /*
         All example code and other macros I've seen build their output using
         strings that are then parsed by `DeclSyntax`. This is implemented using
         types from SwiftSyntax directly, skipping the text parsing step. I
         assume that this is faster, although it's likely negligible.

         I implemented it this way primarily to learn more about the types that
         SwiftSyntax exposes. One nice upside to this is that if it compiles
         then there's more of a chance that it will be valid than arbitrary
         strings concatenated together.
         */
        guard let namedDeclaration = declaration as? NamedDeclSyntax else {
            throw InvalidDeclarationTypeError()
        }

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

        return [
            DeclSyntax(hashFunction),
            DeclSyntax(equalsFunction),
        ]
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
