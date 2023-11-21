// swift-tools-version:5.9
import CompilerPluginSupport
import PackageDescription

let package = Package(
  name: "CustomHashable",
  platforms: [
    .macOS(.v10_15),
    .iOS(.v13),
    .tvOS(.v13),
    .watchOS(.v6),
    .macCatalyst(.v13),
  ],
  products: [
    .library(
      name: "CustomHashable",
      targets: ["CustomHashable"]
    ),
  ],
  dependencies: [
    .package(
      url: "https://github.com/apple/swift-syntax.git",
      from: "509.0.0"
    ),
  ],
  targets: [
    .target(
        name: "CustomHashable",
        dependencies: [
            "CustomHashableMacros",
        ]
    ),
    .macro(
      name: "CustomHashableMacros",
      dependencies: [
        .product(name: "SwiftDiagnostics", package: "swift-syntax"),
        .product(name: "SwiftSyntax", package: "swift-syntax"),
        .product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
        .product(name: "SwiftCompilerPlugin", package: "swift-syntax"),
      ]
    ),
    .testTarget(
      name: "CustomHashableTests",
      dependencies: [
        "CustomHashable",
        "CustomHashableMacros",
        .product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
        .product(name: "SwiftSyntaxMacrosTestSupport", package: "swift-syntax"),
      ]
    ),
  ]
)
