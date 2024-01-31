import SwiftSyntax
import SwiftSyntaxMacros

/// A property that will be included in the implementation of the `Hashable`
/// protocol.
public struct HashedMacro: PeerMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingPeersOf declaration: some DeclSyntaxProtocol,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        // Only used to decorate members
        return []
    }
}
