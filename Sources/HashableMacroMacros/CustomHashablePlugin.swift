import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

@main
struct HashableMacroPlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        HashableMacro.self,
        HashedMacro.self,
        NotHashedMacro.self,
    ]
}
