import SwiftSyntax
import SwiftSyntaxMacros

/// A property that will be included in the implementation of the `Hashable` protocol.
public struct HashableKey: MemberMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        // Only used to decorate members
        return []
    }
}
