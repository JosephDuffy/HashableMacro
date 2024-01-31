import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

@main
struct HashableMacroPlugin: CompilerPlugin {
    #if compiler(>=5.9.2)
    let providingMacros: [Macro.Type] = [
        HashableMacro.self,
        HashedMacro.self,
    ]
    #else
    let providingMacros: [Macro.Type] = [
        HashedMacro.self,
    ]
    #endif
}
