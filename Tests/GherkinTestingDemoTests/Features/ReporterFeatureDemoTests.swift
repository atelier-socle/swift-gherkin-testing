// ReporterFeatureDemoTests.swift
// GherkinTestingDemoTests
//
// Copyright © 2026 Atelier Socle. MIT License.

import Testing
import Foundation
import GherkinTesting

// MARK: - @Feature with Reporters: JSON + HTML generation via gherkinConfiguration

/// Demonstrates how a real developer integrates reporters with `@Feature`.
///
/// The `@Feature` struct overrides ``GherkinFeature/gherkinConfiguration``
/// to attach `CucumberJSONReporter` and `HTMLReporter`. The generated
/// `@Test` methods automatically use this configuration during execution.
///
/// A separate verification test then calls `FeatureExecutor.run()` with
/// fresh reporter instances to validate report output, since the auto-generated
/// tests run independently.
@Feature(source: .inline("""
    @auth @report
    Feature: Login with Reporters
      Background:
        Given the app is launched

      Scenario: Successful login
        Given the user is on the login page
        When they enter "alice" and "secret123"
        Then they should see the dashboard

      Scenario: Failed login
        Given the user is on the login page
        When they enter "alice" and "wrong"
        Then they should see an error message
    """))
struct ReporterLoginFeature {
    let auth = MockAuthService()

    // MARK: - Configuration with reporters

    /// Reporters attached via `gherkinConfiguration`.
    /// The generated @Test methods automatically use this configuration.
    static var gherkinConfiguration: GherkinConfiguration {
        GherkinConfiguration(reporters: [CucumberJSONReporter(), HTMLReporter()])
    }

    // MARK: - Step Definitions

    @Given("the app is launched")
    func appLaunched() async throws {
        await auth.launchApp()
        let launched = await auth.isAppLaunched
        #expect(launched)
    }

    @Given("the user is on the login page")
    func onLoginPage() async throws {
        await auth.navigateToLoginPage()
        let onPage = await auth.isOnLoginPage
        #expect(onPage)
    }

    @When("they enter {string} and {string}")
    func enterCredentials(username: String, password: String) async throws {
        await auth.login(username: username, password: password)
    }

    @Then("they should see the dashboard")
    func seeDashboard() async throws {
        let page = await auth.currentPage
        #expect(page == "dashboard")
    }

    @Then("they should see an error message")
    func seeError() async throws {
        let error = await auth.lastError
        #expect(error == "Invalid username or password")
    }
}

// MARK: - Verification: Reporter output is valid

/// Verifies that reporters produce valid JSON and HTML output after
/// executing a `@Feature` via `FeatureExecutor.run()`.
///
/// This test creates fresh reporter instances, runs the same feature source
/// with `LoginFeature.__stepDefinitions`, and inspects the generated reports.
@Suite("Demo: @Feature with Reporters")
struct ReporterFeatureVerificationTests {

    @Test("Generates non-empty JSON + HTML reports from @Feature execution")
    func jsonAndHtmlReports() async throws {
        let jsonReporter = CucumberJSONReporter()
        let htmlReporter = HTMLReporter()
        let config = GherkinConfiguration(reporters: [jsonReporter, htmlReporter])

        try await FeatureExecutor<ReporterLoginFeature>.run(
            source: .inline("""
                @auth @report
                Feature: Login with Reporters
                  Background:
                    Given the app is launched

                  Scenario: Successful login
                    Given the user is on the login page
                    When they enter "alice" and "secret123"
                    Then they should see the dashboard

                  Scenario: Failed login
                    Given the user is on the login page
                    When they enter "alice" and "wrong"
                    Then they should see an error message
                """),
            definitions: ReporterLoginFeature.__stepDefinitions,
            configuration: config,
            featureFactory: { ReporterLoginFeature() }
        )

        // Verify JSON report
        let jsonData = try await jsonReporter.generateReport()
        #expect(jsonData.count > 0, "JSON report should not be empty")
        let json = try #require(String(data: jsonData, encoding: .utf8))
        #expect(json.contains("\"name\" : \"Login with Reporters\""))
        #expect(json.contains("\"status\" : \"passed\""))

        // Verify HTML report
        let htmlData = try await htmlReporter.generateReport()
        #expect(htmlData.count > 0, "HTML report should not be empty")
        let html = try #require(String(data: htmlData, encoding: .utf8))
        #expect(html.contains("<!DOCTYPE html>"))
        #expect(html.contains("Login with Reporters"))

        // Write both to temp dir and verify files exist
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("gherkin-reporter-feature-\(ProcessInfo.processInfo.globallyUniqueString)")

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
