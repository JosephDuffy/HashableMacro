// swift-tools-version: 6.1
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
    .visionOS(.v1),
  ],
  products: [
    .library(
      name: "HashableMacro",
      targets: ["HashableMacro"]
    ),
  ],
  dependencies: [
    .package(url: "https://github.com/apple/swift-syntax", from: "600.0.0"),
    // We need swift-macro-testing 0.6.0 or newer for compatibility with Swift 6.1 and swift-syntax 600.0.x
    .package(url: "https://github.com/pointfreeco/swift-macro-testing.git", from: "0.6.0"),
  ],
  targets: [
    .target(
        name: "HashableMacro",
        dependencies: [
            .targetItem(
                name: "HashableMacroFoundation",
                condition: .when(
                    platforms: [.macOS, .iOS, .tvOS, .watchOS, .macCatalyst, .visionOS]
                )
            ),
            "HashableMacroMacros",
        ],
        swiftSettings: [.enableExperimentalFeature("StrictConcurrency")]
    ),
    .target(
        name: "HashableMacroFoundation",
        swiftSettings: [.enableExperimentalFeature("StrictConcurrency")]
    ),
    .macro(
      name: "HashableMacroMacros",
      dependencies: [
        .targetItem(
            name: "HashableMacroFoundation",
            condition: .when(
                platforms: [.macOS, .iOS, .tvOS, .watchOS, .macCatalyst]
            )
        ),
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