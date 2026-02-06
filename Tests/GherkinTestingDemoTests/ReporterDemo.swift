// ReporterDemo.swift
// GherkinTestingDemoTests
//
// Copyright © 2026 Atelier Socle. MIT License.

import Testing
import Foundation
import GherkinTesting

// MARK: - Reporter Demo (uses manual runtime API for programmatic result access)
//
// Reporters require programmatic access to TestRunResult, which is not exposed
// by the @Feature macro. The step definitions from macro-generated Feature types
// (LoginFeature.__stepDefinitions, NavigationFeature.__stepDefinitions) are
// reused here to avoid duplication.

@Suite("Demo: Reporters")
struct ReporterDemo {

    @Test("Generates all three report formats from a test run")
    func allReportFormats() async throws {
        let source = try loadFixture("en/login.feature")
        let parser = GherkinParser()
        let document = try parser.parse(source: source)
        let pickles = PickleCompiler().compile(document)

        let jsonReporter = CucumberJSONReporter()
        let xmlReporter = JUnitXMLReporter()
        let htmlReporter = HTMLReporter()

        let config = GherkinConfiguration(
            reporters: [jsonReporter, xmlReporter, htmlReporter]
        )
        let runner = TestRunner(
            definitions: LoginFeature.__stepDefinitions,
            configuration: config
        )

        _ = try await runner.run(
            pickles: pickles,
            featureName: "Login",
            featureTags: ["@auth"],
            feature: LoginFeature()
        )

        // Cucumber JSON
        let jsonData = try await jsonReporter.generateReport()
        let json = try #require(String(data: jsonData, encoding: .utf8))
        #expect(json.contains("\"name\" : \"Login\""))
        #expect(json.contains("\"status\" : \"passed\""))

        // JUnit XML
        let xmlData = try await xmlReporter.generateReport()
        let xml = try #require(String(data: xmlData, encoding: .utf8))
        #expect(xml.contains("<testsuites>"))
        #expect(xml.contains("Feature: Login"))

        // HTML
        let htmlData = try await htmlReporter.generateReport()
        let html = try #require(String(data: htmlData, encoding: .utf8))
        #expect(html.contains("<!DOCTYPE html>"))
        #expect(html.contains("Feature: Login"))
    }

    @Test("CompositeReporter dispatches to multiple reporters")
    func compositeReporter() async throws {
        let source = try loadFixture("en/navigation.feature")
        let parser = GherkinParser()
        let document = try parser.parse(source: source)
        let pickles = PickleCompiler().compile(document)

        let json = CucumberJSONReporter()
        let xml = JUnitXMLReporter()
        let composite = CompositeReporter(reporters: [json, xml])

        let config = GherkinConfiguration(reporters: [composite])
        let runner = TestRunner(
            definitions: NavigationFeature.__stepDefinitions,
            configuration: config
        )

        _ = try await runner.run(
            pickles: pickles,
            featureName: "Navigation",
            featureTags: [],
            feature: NavigationFeature()
        )

        let jsonData = try await json.generateReport()
        let jsonText = try #require(String(data: jsonData, encoding: .utf8))
        #expect(jsonText.contains("Navigation"))

        let xmlData = try await xml.generateReport()
        let xmlText = try #require(String(data: xmlData, encoding: .utf8))
        #expect(xmlText.contains("Navigation"))
    }

    @Test("writeReport(to:) writes all formats to disk")
    func writeReportToDisk() async throws {
        let source = try loadFixture("en/login.feature")
        let parser = GherkinParser()
        let document = try parser.parse(source: source)
        let pickles = PickleCompiler().compile(document)

        let reporter = CucumberJSONReporter()
        let config = GherkinConfiguration(reporters: [reporter])
        let runner = TestRunner(
            definitions: LoginFeature.__stepDefinitions,
            configuration: config
        )

        _ = try await runner.run(
            pickles: pickles,
            featureName: "Login",
            featureTags: [],
            feature: LoginFeature()
        )

        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("gherkin-demo-\(ProcessInfo.processInfo.globallyUniqueString)")
        let fileURL = tempDir.appendingPathComponent("report.json")

        try await reporter.writeReport(to: fileURL)

        let written = try Data(contentsOf: fileURL)
        #expect(written.count > 0)

        try FileManager.default.removeItem(at: tempDir)
    }
}
