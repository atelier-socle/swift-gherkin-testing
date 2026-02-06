// SwiftTestingCodeGen.swift
// GherkinTestingMacros
//
// Copyright © 2026 Atelier Socle. MIT License.

import SwiftSyntax
import SwiftSyntaxBuilder

/// Generates Swift Testing `@Suite`/`@Test` structures for feature execution.
///
/// Used by ``FeatureMacro`` for generating the test suite declarations.
/// All string escaping uses ``SyntaxHelpers`` (no Foundation dependency).
enum SwiftTestingCodeGen {

    /// Generates a `@Suite` struct with `@Test` methods for an inline Gherkin source.
    ///
    /// For inline sources, each scenario in the Gherkin text gets its own `@Test` method.
    /// The generated struct calls `FeatureExecutor<F>.run(...)` at runtime.
    ///
    /// - Parameters:
    ///   - typeName: The original feature struct name.
    ///   - source: The inline Gherkin source string.
    ///   - scenarioNames: The extracted scenario names.
    /// - Returns: An array of `DeclSyntax` declarations (extension + @Suite struct).
    static func generateInlineTestSuite(
        typeName: String,
        source: String,
        scenarioNames: [String]
    ) -> [DeclSyntax] {
        let suiteName = "\(typeName)__GherkinTests"
        let escapedSource = SyntaxHelpers.escapeForStringLiteral(source)

        var testMethods: [String] = []

        if scenarioNames.isEmpty {
            testMethods.append(
                """
                    @Test("Feature: \(typeName)")
                    func feature_test() async throws {
                        try await FeatureExecutor<\(typeName)>.run(
                            source: .inline("\(escapedSource)"),
                            definitions: \(typeName).__stepDefinitions,
                            featureFactory: { \(typeName)() }
                        )
                    }
                """)
        } else {
            for name in scenarioNames {
                let methodName = "scenario_\(SyntaxHelpers.sanitizeIdentifier(name))"
                let displayName = SyntaxHelpers.escapeForStringLiteral(name)
                testMethods.append(
                    """
                        @Test("Scenario: \(displayName)")
                        func \(methodName)() async throws {
                            try await FeatureExecutor<\(typeName)>.run(
                                source: .inline("\(escapedSource)"),
                                definitions: \(typeName).__stepDefinitions,
                                scenarioFilter: "\(displayName)",
                                featureFactory: { \(typeName)() }
                            )
                        }
                    """)
            }
        }

        let conformanceDecl: DeclSyntax = """
            extension \(raw: typeName): GherkinFeature {}
            """

        let methods = testMethods.joined(separator: "\n\n")
        let suiteDecl: DeclSyntax = """
            @Suite("\(raw: typeName)")
            struct \(raw: suiteName) {
            \(raw: methods)
            }
            """

        return [conformanceDecl, suiteDecl]
    }

    /// Generates a `@Suite` struct with a single `@Test` for a file-based source.
    ///
    /// File sources are parsed at runtime, so only a single `@Test` is generated.
    ///
    /// - Parameters:
    ///   - typeName: The original feature struct name.
    ///   - filePath: The .feature file path.
    /// - Returns: An array of `DeclSyntax` declarations.
    static func generateFileTestSuite(
        typeName: String,
        filePath: String
    ) -> [DeclSyntax] {
        let suiteName = "\(typeName)__GherkinTests"
        let escapedPath = SyntaxHelpers.escapeForStringLiteral(filePath)

        let conformanceDecl: DeclSyntax = """
            extension \(raw: typeName): GherkinFeature {}
            """

        let suiteDecl: DeclSyntax = """
            @Suite("\(raw: typeName)")
            struct \(raw: suiteName) {
                @Test("Feature: \(raw: typeName)")
                func feature_test() async throws {
                    try await FeatureExecutor<\(raw: typeName)>.run(
                        source: .file("\(raw: escapedPath)"),
                        definitions: \(raw: typeName).__stepDefinitions,
                        featureFactory: { \(raw: typeName)() }
                    )
                }
            }
            """

        return [conformanceDecl, suiteDecl]
    }
}
