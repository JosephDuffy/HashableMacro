// swift-tools-version: 5.9
import CompilerPluginSupport
import PackageDescription

let package = Package(
  name: "HashableMacro",
  platforms: [
    .macOS(.v10_15),
    .iOS(.v13),
    .tvOS(.v13),
    .watchOS(.v6),
    .macCatalyst(.v13),
  ],
  products: [
    .library(
      name: "HashableMacro",
      targets: ["HashableMacro"]
    ),
  ],
  dependencies: [
    .package(
      url: "https://github.com/apple/swift-syntax.git",
      from: "509.1.0"
    ),
    .package(
        url: "https://github.com/pointfreeco/swift-macro-testing.git",
        branch: "main" // Needed to test diagnostics. 0.2.3 or higher should be ok.
    ),
  ],
  targets: [
    .target(
        name: "HashableMacro",
        dependencies: [
            "HashableMacroMacros",
        ],
        swiftSettings: [.enableExperimentalFeature("StrictConcurrency")]
    ),
    .macro(
      name: "HashableMacroMacros",
      dependencies: [
        .product(name: "SwiftDiagnostics", package: "swift-syntax"),
        .product(name: "SwiftSyntax", package: "swift-syntax"),
        .product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
        .product(name: "SwiftCompilerPlugin", package: "swift-syntax"),
      ],
      swiftSettings: [.enableExperimentalFeature("StrictConcurrency")]
    ),
    .testTarget(
      name: "HashableMacroTests",
      dependencies: [
        "HashableMacro",
        "HashableMacroMacros",
        .product(name: "MacroTesting", package: "swift-macro-testing"),
        .product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
        .product(name: "SwiftSyntaxMacrosTestSupport", package: "swift-syntax"),
      ],
      swiftSettings: [.enableExperimentalFeature("StrictConcurrency")]
    ),
  ]
)
