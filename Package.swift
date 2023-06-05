// swift-tools-version:5.9
import CompilerPluginSupport
import PackageDescription

let package = Package(
  name: "CustomHashable",
  platforms: [
    .iOS(.v16),
    .macOS(.v13),
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
      from: "509.0.0-swift-5.9-DEVELOPMENT-SNAPSHOT-2023-04-25-b"
    ),
  ],
  targets: [
    .macro(
      name: "CustomHashablePlugin",
      dependencies: [
        .product(name: "SwiftDiagnostics", package: "swift-syntax"),
        .product(name: "SwiftSyntax", package: "swift-syntax"),
        .product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
        .product(name: "SwiftCompilerPlugin", package: "swift-syntax"),
      ]
    ),
    .target(
      name: "CustomHashable",
      dependencies: [
        "CustomHashablePlugin",
      ],
      swiftSettings: [
        .enableExperimentalFeature("Macros"),
      ]
    ),
    .testTarget(
      name: "CustomHashableTests",
      dependencies: ["CustomHashable"]
    ),
  ]
)
