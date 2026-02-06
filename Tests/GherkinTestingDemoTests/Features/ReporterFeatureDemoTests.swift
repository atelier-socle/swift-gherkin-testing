// ReporterFeatureDemoTests.swift
// GherkinTestingDemoTests
//
// Copyright © 2026 Atelier Socle. MIT License.

import Foundation
import GherkinTesting
import Testing

// MARK: - @Feature with Reporters: JSON + JUnit XML + HTML via CompositeReporter

/// Demonstrates how a real developer integrates reporters with `@Feature`.
///
/// The `@Feature` struct overrides ``GherkinFeature/gherkinConfiguration``
/// to attach a `CompositeReporter` wrapping all three reporter types
/// (`CucumberJSONReporter`, `JUnitXMLReporter`, `HTMLReporter`).
///
/// A separate verification test then calls `FeatureExecutor.run()` with
/// fresh reporter instances to validate report output, since the auto-generated
/// tests run independently.
@Feature(
    source: .inline(
        """
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

    // MARK: - Configuration with CompositeReporter wrapping all 3 formats

    /// CompositeReporter dispatches events to JSON, JUnit XML, and HTML reporters.
    static var gherkinConfiguration: GherkinConfiguration {
        GherkinConfiguration(reporters: [
            CompositeReporter(reporters: [
                CucumberJSONReporter(),
                JUnitXMLReporter(),
                HTMLReporter()
            ])
        ])
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

// MARK: - Verification: All 3 reporter formats + CompositeReporter + writeReport

/// Verifies that all three reporter formats produce valid output via CompositeReporter
/// and that `writeReport(to:)` writes files to disk.
@Suite("Demo: @Feature with Reporters")
struct ReporterFeatureVerificationTests {

    @Test("Generates JSON, JUnit XML, and HTML reports via CompositeReporter")
    func allReportFormats() async throws {
        let jsonReporter = CucumberJSONReporter()
        let xmlReporter = JUnitXMLReporter()
        let htmlReporter = HTMLReporter()
        let composite = CompositeReporter(reporters: [jsonReporter, xmlReporter, htmlReporter])

        let config = GherkinConfiguration(reporters: [composite])

        try await FeatureExecutor<ReporterLoginFeature>.run(
            source: .inline(
                """
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

        // Verify Cucumber JSON report
        let jsonData = try await jsonReporter.generateReport()
        #expect(jsonData.count > 0, "JSON report should not be empty")
        let json = try #require(String(data: jsonData, encoding: .utf8))
        #expect(json.contains("\"name\" : \"Login with Reporters\""))
        #expect(json.contains("\"status\" : \"passed\""))

        // Verify JUnit XML report
        let xmlData = try await xmlReporter.generateReport()
        #expect(xmlData.count > 0, "JUnit XML report should not be empty")
        let xml = try #require(String(data: xmlData, encoding: .utf8))
        #expect(xml.contains("<testsuites>"))
        #expect(xml.contains("Feature: Login with Reporters"))

        // Verify HTML report
        let htmlData = try await htmlReporter.generateReport()
        #expect(htmlData.count > 0, "HTML report should not be empty")
        let html = try #require(String(data: htmlData, encoding: .utf8))
        #expect(html.contains("<!DOCTYPE html>"))
        #expect(html.contains("Login with Reporters"))

        // Write all reports to temp dir via writeReport(to:)
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("gherkin-reporter-feature-\(ProcessInfo.processInfo.globallyUniqueString)")

        let jsonURL = tempDir.appendingPathComponent("cucumber.json")
        let xmlURL = tempDir.appendingPathComponent("junit.xml")
        let htmlURL = tempDir.appendingPathComponent("report.html")

        try await jsonReporter.writeReport(to: jsonURL)
        try await xmlReporter.writeReport(to: xmlURL)
        try await htmlReporter.writeReport(to: htmlURL)

        let jsonFile = try Data(contentsOf: jsonURL)
        let xmlFile = try Data(contentsOf: xmlURL)
        let htmlFile = try Data(contentsOf: htmlURL)
        #expect(jsonFile.count > 0, "Written JSON file should not be empty")
        #expect(xmlFile.count > 0, "Written XML file should not be empty")
        #expect(htmlFile.count > 0, "Written HTML file should not be empty")

        try FileManager.default.removeItem(at: tempDir)
    }
}
