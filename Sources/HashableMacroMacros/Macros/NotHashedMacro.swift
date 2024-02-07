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
        // Only used to decorate members
        return []
    }
}
