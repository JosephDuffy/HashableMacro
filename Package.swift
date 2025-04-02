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
    .visionOS(.v1),
  ],
  products: [
    .library(
      name: "HashableMacro",
      targets: ["HashableMacro"]
    ),
  ],
  dependencies: [
    .package(url: "https://github.com/apple/swift-syntax", from: "509.1.0"),
    // We only really need swift-macro-testing 0.3.0 or newer but 0.4.0 is required to compile due
    // to breaking changes in swift-snapshot-testing.
    .package(url: "https://github.com/pointfreeco/swift-macro-testing.git", from: "0.4.0"),
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
      swiftSettings: [
        .enableExperimentalFeature("StrictConcurrency"),
        .unsafeFlags(
            [
                "-Xfrontend", "-entry-point-function-name",
                "-Xfrontend", "wWinMain",
            ],
            .when(platforms: [.windows])
        ),
      ]
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
