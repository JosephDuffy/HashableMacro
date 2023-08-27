import Foundation
import SwiftDiagnostics
import SwiftSyntax
import SwiftSyntaxMacros

public struct CustomHashable: ExtensionMacro, MemberMacro {
    public static func expansion(
        of node: AttributeSyntax,
        attachedTo declaration: some DeclGroupSyntax,
        providingExtensionsOf type: some TypeSyntaxProtocol,
        conformingTo protocols: [TypeSyntax],
        in context: some MacroExpansionContext
    ) throws -> [ExtensionDeclSyntax] {
        guard let hashableType = protocols.first else {
            // Hashable conformance has been explicitly added.
            return []
        }

        assert("\(hashableType.trimmed)" == "Hashable", "Only expected to add Hashable conformance")
        assert(protocols.count == 1, "Only expected to add conformance to a single protocol")

        return [
            ExtensionDeclSyntax(
                extendedType: type,
                inheritanceClause: InheritanceClauseSyntax(
                    inheritedTypes: InheritedTypeListSyntax(itemsBuilder: {
                        InheritedTypeSyntax(
                            type: hashableType
                        )
                    })
                ),
                memberBlock: MemberBlockSyntax(members: "")
            )
        ]
    }

    public static func expansion(
        of node: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
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

        let scope = ({
            for modifier in declaration.modifiers {
                switch (modifier.name.tokenKind) {
                case .keyword(.public):
                    return "public "
                case .keyword(.internal):
                    return "internal "
                case .keyword(.fileprivate):
                    return "fileprivate "
                case .keyword(.private):
                    // The added functions should never be private
                    return ""
                default:
                    break
                }
            }

            return ""
        })()

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

        var hashIntoImplementation: String =  """
            \(scope)func hash(into hasher: inout Hasher) {
        """

        let equalsFunctionSignature = FunctionSignatureSyntax(
            parameterClause: FunctionParameterClauseSyntax(
                parameters: [
                    FunctionParameterSyntax(
                        firstName: TokenSyntax.identifier("lhs"),
                        type: TypeSyntax(stringLiteral: namedDeclaration.name.text),
                        trailingComma: .commaToken(trailingTrivia: .space)
                    ),
                    FunctionParameterSyntax(
                        firstName: TokenSyntax.identifier("rhs"),
                        type: TypeSyntax(stringLiteral: namedDeclaration.name.text)
                    ),
                ],
                rightParen: TokenSyntax.rightParenToken(trailingTrivia: .space)
            ),
            returnClause: ReturnClauseSyntax(
                arrow: .arrowToken(trailingTrivia: .space),
                type: IdentifierTypeSyntax(name: .identifier("Bool")),
                trailingTrivia: .space
            )
        )

        // Newline leading trivia cannot be used here; it produces an error:
        // > swift-syntax applies macros syntactically and there is no way to represent a variable declaration with multiple bindings that have accessors syntactically. While the compiler allows this expansion, swift-syntax cannot represent it and thus disallows it.
        let equalsBody = CodeBlockSyntax(
            leftBrace: .leftBraceToken(trailingTrivia: .newline),
            statements: CodeBlockItemListSyntax(itemsBuilder: {
                CodeBlockItemSyntax(
                    item: CodeBlockItemSyntax.Item(
                        ReturnStmtSyntax(trailingTrivia: .space)
                    )
                )

                if propertyNames.isEmpty {
                    CodeBlockItemSyntax(
                        item: CodeBlockItemSyntax.Item(
                            BooleanLiteralExprSyntax(booleanLiteral: true)
                        )
                    )
                }

                for (index, propertyToken) in propertyNames.enumerated() {
                    //MemberAccessExprSyntax
                    CodeBlockItemSyntax(
                        item: CodeBlockItemSyntax.Item(
                            SequenceExprSyntax(
                                elementsBuilder: {
                                    MemberAccessExprSyntax(
                                        base: DeclReferenceExprSyntax(
                                            baseName: .identifier("lhs")
                                        ),
                                        declName: DeclReferenceExprSyntax(
                                            baseName: propertyToken
                                        )
                                    )
                                }
                            )
                        )
                    )

                    BinaryOperatorExprSyntax(
                        leadingTrivia: .space,
                        operator: .binaryOperator("=="),
                        trailingTrivia: .space
                    )

                    CodeBlockItemSyntax(
                        item: CodeBlockItemSyntax.Item(
                            SequenceExprSyntax(
                                elementsBuilder: {
                                    MemberAccessExprSyntax(
                                        base: DeclReferenceExprSyntax(
                                            baseName: .identifier("rhs")
                                        ),
                                        declName: DeclReferenceExprSyntax(
                                            baseName: propertyToken
                                        )
                                    )
                                }
                            )
                        )
                    )

                    if index + 1 != propertyNames.count {
                        BinaryOperatorExprSyntax(
                            leadingTrivia: .newline.appending(Trivia.spaces(4)),
                            operator: .binaryOperator("&&"),
                            trailingTrivia: .space
                        )
                    }
                }
            }),
            rightBrace: .rightBraceToken(leadingTrivia: .newline)
        )

        var equalsFunctionModifiers = baseModifiers
        equalsFunctionModifiers.append(
            DeclModifierSyntax(name: .keyword(.static, trailingTrivia: .space))
        )

        let equalsFunction = FunctionDeclSyntax(
            modifiers: equalsFunctionModifiers,
            funcKeyword: .keyword(.func, trailingTrivia: .space),
            name: TokenSyntax.identifier("=="),
            signature: equalsFunctionSignature,
            body: equalsBody
        )

        for propertyName in propertyNames {
            hashIntoImplementation += "\n"
            hashIntoImplementation += "hasher.combine(\(propertyName))"
        }

        hashIntoImplementation += "\n"
        hashIntoImplementation += "}"

        return [
            "\(raw: hashIntoImplementation)",
            "\(equalsFunction)",
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
