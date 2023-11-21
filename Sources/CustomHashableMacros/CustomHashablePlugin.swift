import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

@main
struct CustomHashablePlugin: CompilerPlugin {
  let providingMacros: [Macro.Type] = [
    CustomHashable.self,
    HashableKey.self,
  ]
}
