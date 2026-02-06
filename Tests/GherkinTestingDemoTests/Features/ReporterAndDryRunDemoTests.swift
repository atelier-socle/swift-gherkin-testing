// ReporterAndDryRunDemoTests.swift
// GherkinTestingDemoTests
//
// Copyright © 2026 Atelier Socle. MIT License.

import Testing
import Foundation
import GherkinTesting

// MARK: - Reporter Demo: JSON + HTML generation with macro-generated definitions

/// Demonstrates generating JSON and HTML reports from a macro-generated @Feature.
///
/// Reporters require direct access to `TestRunResult`, which is only available
/// via the programmatic `TestRunner` API. Step definitions are reused from
/// `LoginFeature.__stepDefinitions`.
@Suite("Demo: Reporters with Macros")
struct ReporterWithMacrosDemoTests {

    @Test("Generates JSON + HTML reports from LoginFeature steps, verifies non-empty")
    func jsonAndHtmlReports() async throws {
        let source = try loadFixture("en/login.feature")
        let parser = GherkinParser()
        let document = try parser.parse(source: source)
        let pickles = PickleCompiler().compile(document)

        let jsonReporter = CucumberJSONReporter()
        let htmlReporter = HTMLReporter()

        let config = GherkinConfiguration(
            reporters: [jsonReporter, htmlReporter]
        )
        let runner = TestRunner(
            definitions: LoginFeature.__stepDefinitions,
            configuration: config
        )

        _ = try await runner.run(
            pickles: pickles,
            featureName: "Login",
            featureTags: ["@auth", "@smoke"],
            feature: LoginFeature()
        )

        // Verify JSON report is valid and non-empty
        let jsonData = try await jsonReporter.generateReport()
        #expect(jsonData.count > 0, "JSON report should not be empty")
        let json = try #require(String(data: jsonData, encoding: .utf8))
        #expect(json.contains("\"name\" : \"Login\""))
        #expect(json.contains("\"status\" : \"passed\""))

        // Verify HTML report is valid and non-empty
        let htmlData = try await htmlReporter.generateReport()
        #expect(htmlData.count > 0, "HTML report should not be empty")
        let html = try #require(String(data: htmlData, encoding: .utf8))
        #expect(html.contains("<!DOCTYPE html>"))
        #expect(html.contains("Login"))

        // Write both to temp dir and verify files exist
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("gherkin-reporter-demo-\(ProcessInfo.processInfo.globallyUniqueString)")

        let jsonURL = tempDir.appendingPathComponent("cucumber.json")
        let htmlURL = tempDir.appendingPathComponent("report.html")

        try await jsonReporter.writeReport(to: jsonURL)
        try await htmlReporter.writeReport(to: htmlURL)

        let jsonFile = try Data(contentsOf: jsonURL)
        let htmlFile = try Data(contentsOf: htmlURL)
        #expect(jsonFile.count > 0, "Written JSON file should not be empty")
        #expect(htmlFile.count > 0, "Written HTML file should not be empty")

        try FileManager.default.removeItem(at: tempDir)
    }
}

// MARK: - Dry-Run Demo: undefined steps generate suggestions

/// A feature struct with NO step definitions, used to demonstrate dry-run mode.
private struct EmptyFeature: GherkinFeature {}

@Suite("Demo: Dry-Run with Suggestions")
struct DryRunDemoTests {

    @Test("Dry-run on feature with undefined steps produces suggestions")
    func dryRunSuggestions() async throws {
        let source = """
            Feature: Undefined Steps
              Scenario: Unimplemented scenario
                Given the user has 42 items
                When they add "apples" to the cart
                Then the total is 9.99
            """

        let parser = GherkinParser()
        let document = try parser.parse(source: source)
        let pickles = PickleCompiler().compile(document)

        let config = GherkinConfiguration(dryRun: true)
        let runner = TestRunner<EmptyFeature>(
            definitions: [],
            configuration: config
        )

        let result = try await runner.run(
            pickles: pickles,
            featureName: "Undefined Steps",
            featureTags: [],
            feature: EmptyFeature()
        )

        // All 3 steps should be undefined
        let suggestions = result.allSuggestions
        #expect(suggestions.count == 3, "Expected 3 suggestions for 3 undefined steps")

        // Verify suggestions contain Cucumber expression placeholders
        let expressions = suggestions.map(\.suggestedExpression)
        #expect(expressions.contains { $0.contains("{int}") })
        #expect(expressions.contains { $0.contains("{string}") })
        #expect(expressions.contains { $0.contains("{float}") })

        // Verify generated code skeletons
        for suggestion in suggestions {
            #expect(suggestion.suggestedSignature.contains("func "))
            #expect(suggestion.suggestedSignature.contains("PendingStepError"))
        }
    }
}
