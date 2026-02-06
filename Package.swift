// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription
import CompilerPluginSupport

let package = Package(
    name: "swift-gherkin-testing",
    platforms: [
        .iOS(.v17),
        .macOS(.v14),
        .tvOS(.v17),
        .watchOS(.v10),
        .visionOS(.v1),
        .macCatalyst(.v17)
    ],
    products: [
        .library(
            name: "GherkinTesting",
            targets: ["GherkinTesting"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/swiftlang/swift-syntax.git", from: "601.0.0")
    ],
    targets: [
        // MARK: - Macro Plugin (compiler only, not shipped at runtime)
        .macro(
            name: "GherkinTestingMacros",
            dependencies: [
                .product(name: "SwiftSyntax", package: "swift-syntax"),
                .product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
                .product(name: "SwiftSyntaxBuilder", package: "swift-syntax"),
                .product(name: "SwiftCompilerPlugin", package: "swift-syntax")
            ],
            path: "Sources/GherkinTestingMacros"
        ),

        // MARK: - Main Library
        .target(
            name: "GherkinTesting",
            dependencies: ["GherkinTestingMacros"],
            path: "Sources/GherkinTesting",
            resources: [
                .copy("I18n/Resources/gherkin-languages.json")
            ],
        ),

        // MARK: - Library Tests
        .testTarget(
            name: "GherkinTestingTests",
            dependencies: ["GherkinTesting"],
            path: "Tests/GherkinTestingTests",
            resources: [
                .copy("Fixtures")
            ]
        ),

        // MARK: - Macro Expansion Tests
        .testTarget(
            name: "GherkinTestingMacroTests",
            dependencies: [
                "GherkinTestingMacros",
                .product(name: "SwiftSyntaxMacrosTestSupport", package: "swift-syntax")
            ],
            path: "Tests/GherkinTestingMacroTests"
        ),

        // MARK: - Demo / Integration Tests
        .testTarget(
            name: "GherkinTestingDemoTests",
            dependencies: ["GherkinTesting"],
            path: "Tests/GherkinTestingDemoTests",
            resources: [
                .copy("Fixtures")
            ]
        )
    ]
)
