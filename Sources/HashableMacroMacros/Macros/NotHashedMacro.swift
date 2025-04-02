import SwiftDiagnostics
import SwiftSyntax
import SwiftSyntaxMacros

/// A property that will be excluded in the implementation of the `Hashable`
/// protocol.
public struct NotHashedMacro: PeerMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingPeersOf declaration: some DeclSyntaxProtocol,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        guard let variable = declaration.as(VariableDeclSyntax.self) else {
            let fixIt = FixIt(
                message: HashableMacroFixItMessage(
                    id: "not-hashed-added-to-unsupported-node",
                    message: "Remove @NotHashed"
                ),
                changes: [
                    FixIt.Change.replace(
                        oldNode: Syntax(node),
                        newNode: Syntax("" as DeclSyntax)
                    )
                ]
            )
            let diagnostic = Diagnostic(
                node: Syntax(node),
                message: HashableMacroDiagnosticMessage(
                    id: "nothashed-added-to-unsupported-node",
                    message: "The @NotHashed macro is only supported on properties.",
                    severity: .warning
                ),
                fixIt: fixIt
            )
            context.diagnose(diagnostic)
            return []
        }

        if !isSupportedOnVariable(variable) {
            let fixIt = FixIt(
                message: HashableMacroFixItMessage(
                    id: "not-hashed-added-to-unsupported-variable",
                    message: "Remove @NotHashed"
                ),
                changes: [
                    FixIt.Change.replace(
                        oldNode: Syntax(node),
                        newNode: Syntax("" as DeclSyntax)
                    )
                ]
            )
            let diagnostic = Diagnostic(
                node: Syntax(node),
                message: HashableMacroDiagnosticMessage(
                    id: "not-hashed-added-to-unsupported-variable",
                    message: "The @NotHashed macro is only supported on instance properties.",
                    severity: .warning
                ),
                fixIt: fixIt
            )
            context.diagnose(diagnostic)
        }

        // Only used to decorate members
        return []
    }

    public static func isSupportedOnVariable(_ variable: VariableDeclSyntax) -> Bool {
        variable.modifiers.allSatisfy { modifier in
            let tokenKind = modifier.name.trimmed.tokenKind
            return tokenKind != .keyword(.static) && tokenKind != .keyword(.class)
        }
    }
}
