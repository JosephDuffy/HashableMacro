#if canImport(SwiftCompilerPlugin)
import SwiftCompilerPlugin
import SwiftSyntaxMacros

@main
struct CustomHashablePlugin: CompilerPlugin {
  let providingMacros: [Macro.Type] = [
    CustomHashable.self,
    HashableKey.self,
  ]
}
#endif
