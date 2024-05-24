import Foundation
import SwiftDiagnostics
import SwiftSyntax
import SwiftSyntaxMacros

extension HashableMacro {
    static func expansionForHashable(
        of node: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        in context: some MacroExpansionContext,
        propertiesToHash: [TokenSyntax]
    ) -> DeclSyntax {
        var finalHashInto = true

        if let arguments = node.arguments?.as(LabeledExprListSyntax.self) {
            for argument in arguments {
                guard let label = argument.label else { continue }
                switch label.trimmed.text {
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
            case .keyword(.public), .keyword(.internal), .keyword(.fileprivate), .keyword(.package):
                // Only public is truly needed, but we can be explicit with the others.
                return true
            case .keyword(.open) where !finalHashInto:
                return true
            case .keyword(.private), .keyword(.open):
                // The added functions should never be private because they're in an extension. open
                // is also ignored when `hash(into:)` is final.
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

    static func expansionForEquals(
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

        var customFullyQualifiedName: String?

        if let arguments = node.arguments?.as(LabeledExprListSyntax.self) {
            for argument in arguments {
                guard let label = argument.label else { continue }
                switch label.trimmed.text {
                case "fullyQualifiedName":
                    guard let stringExpression = argument.expression.as(StringLiteralExprSyntax.self) else { continue }
                    customFullyQualifiedName = "\(stringExpression.segments)"
                default:
                    break
                }
            }
        }

        let hashableType: IdentifierTypeSyntax

        if let customFullyQualifiedName {
            hashableType = IdentifierTypeSyntax(name: .identifier(customFullyQualifiedName))
        } else if declaration.is(StructDeclSyntax.self) {
            hashableType = IdentifierTypeSyntax(name: .keyword(.Self))
        } else {
            hashableType = IdentifierTypeSyntax(name: .identifier(namedDeclaration.name.text))
        }

        let equalsFunctionSignature = FunctionSignatureSyntax(
            parameterClause: FunctionParameterClauseSyntax(
                parameters: [
                    FunctionParameterSyntax(
                        firstName: .identifier("lhs"),
                        type: hashableType,
                        trailingComma: .commaToken()
                    ),
                    FunctionParameterSyntax(
                        firstName: .identifier("rhs"),
                        type: hashableType
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

        var equalsFunctionModifiers = DeclModifierListSyntax(declaration.modifiers.compactMap { modifier in
            switch (modifier.name.tokenKind) {
            case .keyword(.public), .keyword(.internal), .keyword(.fileprivate), .keyword(.package):
                // Only public is truly needed, but we can be explicit with the others.
                return modifier
            case .keyword(.open):
                // `==` is implicitly final; it cannot be open but it does need to be public.
                return DeclModifierSyntax(name: .keyword(.public))
            default:
                // Anything else, e.g. private and final, should be discarded.
                return nil
            }
        })
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
}
