#if canImport(ObjectiveC)
import Foundation
import HashableMacroFoundation
import SwiftDiagnostics
import SwiftSyntax
import SwiftSyntaxMacros

extension HashableMacro {
    static func expansionForHashProperty(
        of node: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        in context: some MacroExpansionContext,
        propertiesToHash: [TokenSyntax]
    ) -> DeclSyntax {
        var hashPropertyModifiers = DeclModifierListSyntax(declaration.modifiers.compactMap { modifier in
            switch (modifier.name.tokenKind) {
            case .keyword(.public), .keyword(.internal), .keyword(.fileprivate), .keyword(.package):
                // Only public is truly needed, but we can be explicit with the others.
                return modifier
            case .keyword(.open):
                // This property is final and cannot be open.
                var modifier = modifier
                modifier.name.tokenKind = .keyword(.public)
                return modifier
            default:
                // Anything else, e.g. private and final, should be discarded.
                return nil
            }
        })
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
                            let havePropertiesToHash = !propertiesToHash.isEmpty

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

    static func expansionForIsEqual(
        of node: AttributeSyntax,
        providingMembersOf declaration: ClassDeclSyntax,
        in context: some MacroExpansionContext,
        propertiesToHash: [TokenSyntax],
        isEqualToTypeFunctionName: IsEqualToTypeFunctionNameGeneration
    ) -> [DeclSyntax] {
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
                        leadingTrivia: .newline.appending(Trivia.spaces(4)),
                        operator: .binaryOperator("&&")
                    ),
                    rightOperand: comparison
                )
            } else {
                comparisons = comparison
            }
        }

        let isEqualAnyBody = CodeBlockSyntax(
            statements: CodeBlockItemListSyntax(itemsBuilder: {
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
                                        name: declaration.name
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

                ReturnStmtSyntax(
                    expression: FunctionCallExprSyntax(
                        calledExpression: MemberAccessExprSyntax(
                            base: DeclReferenceExprSyntax(baseName: .keyword(.`self`)),
                            declName: DeclReferenceExprSyntax(baseName: .identifier("isEqual"))
                        ),
                        leftParen: .leftParenToken(),
                        arguments: [
                            LabeledExprSyntax(
                                label: "to",
                                expression: DeclReferenceExprSyntax(
                                    baseName: .identifier("object")
                                )
                            )
                        ],
                        rightParen: .rightParenToken()
                    )
                )
            })
        )

        let isEqualTypedBody = CodeBlockSyntax(
            statements: CodeBlockItemListSyntax(itemsBuilder: {
                if let comparisons {
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

        var equalsFunctionModifiers = declaration.modifiers.filter({ modifier in
            switch (modifier.name.tokenKind) {
            case .keyword(.open), .keyword(.public), .keyword(.internal), .keyword(.fileprivate), .keyword(.package):
                // Only open and public are truly needed, but we can be explicit with the others.
                return true
            default:
                // Anything else, e.g. private and final, should be discarded.
                return false
            }
        })
        equalsFunctionModifiers.append(
            DeclModifierSyntax(name: .keyword(.override))
        )

        let isEqualAnyFunction = FunctionDeclSyntax(
            modifiers: equalsFunctionModifiers,
            name: .identifier("isEqual"),
            signature: FunctionSignatureSyntax(
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
            ),
            body: isEqualAnyBody
        )

        let objectiveCName: TokenSyntax
        switch isEqualToTypeFunctionName {
        case .automatic:
            objectiveCName = .identifier("isEqualTo\(declaration.name.trimmed):")
        case .custom(let customName):
            objectiveCName = .identifier(customName)
        }

        var isEqualTypedFunctionModifiers = DeclModifierListSyntax(declaration.modifiers.compactMap { modifier in
            switch (modifier.name.tokenKind) {
            case .keyword(.public), .keyword(.internal), .keyword(.fileprivate), .keyword(.package):
                // Only public is truly needed, but we can be explicit with the others.
                return modifier
            case .keyword(.open):
                // This function is final and cannot be open.
                var modifier = modifier
                modifier.name.tokenKind = .keyword(.public)
                return modifier
            default:
                // Anything else, e.g. private and final, should be discarded.
                return nil
            }
        })
        isEqualTypedFunctionModifiers.append(
            DeclModifierSyntax(name: .keyword(.final))
        )

        let isEqualTypedFunction = FunctionDeclSyntax(
            attributes: AttributeListSyntax {
                .attribute(
                    AttributeSyntax(
                        attributeName: IdentifierTypeSyntax(name: .identifier("objc")),
                        leftParen: .leftParenToken(),
                        arguments: .objCName([
                            ObjCSelectorPieceSyntax(name: objectiveCName),
                        ]),
                        rightParen: .rightParenToken(),
                        trailingTrivia: .newline
                    )
                )
            },
            modifiers: isEqualTypedFunctionModifiers,
            name: .identifier("isEqual"),
            signature: FunctionSignatureSyntax(
                parameterClause: FunctionParameterClauseSyntax(
                    parameters: [
                        FunctionParameterSyntax(
                            firstName: .identifier("to"),
                            secondName: .identifier("object"),
                            type: IdentifierTypeSyntax(name: declaration.name)
                        )
                    ]
                ),
                returnClause: ReturnClauseSyntax(
                    type: IdentifierTypeSyntax(name: .identifier("Bool"))
                )
            ),
            body: isEqualTypedBody
        )

        return [
            DeclSyntax(isEqualAnyFunction),
            DeclSyntax(isEqualTypedFunction),
        ]
    }
}
#endif
