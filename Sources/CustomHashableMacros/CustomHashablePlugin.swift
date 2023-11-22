import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

@main
struct CustomHashablePlugin: CompilerPlugin {
#if swift(>=5.9.2)
    let providingMacros: [Macro.Type] = [
        CustomHashable.self,
        HashableKey.self,
    ]
#else
    let providingMacros: [Macro.Type] = [
        HashableKey.self,
    ]
#endif
}
