// ReporterIntegrationTests.swift
// GherkinTestingTests
//
// Copyright © 2026 Atelier Socle. MIT License.

import Foundation
import Testing

@testable import GherkinTesting

/// A minimal feature for reporter integration tests.
private struct ReporterTestFeature: GherkinFeature {}

/// A spy reporter that tracks events received from TestRunner.
private actor EventTracker: GherkinReporter {
    var events: [String] = []

    func featureStarted(_ feature: FeatureResult) {
        events.append("featureStarted:\(feature.name)")
    }

    func scenarioStarted(_ scenario: ScenarioResult) {
        events.append("scenarioStarted:\(scenario.name)")
    }

    func stepFinished(_ step: StepResult) {
        events.append("stepFinished:\(step.step.text)")
    }

    func scenarioFinished(_ scenario: ScenarioResult) {
        events.append("scenarioFinished:\(scenario.name)")
    }

    func featureFinished(_ feature: FeatureResult) {
        events.append("featureFinished:\(feature.name)")
    }

    func testRunFinished(_ result: TestRunResult) {
        events.append("testRunFinished:\(result.totalCount)")
    }

    func generateReport() throws -> Data {
        Data()
    }
}

private func makePickle(
    name: String,
    steps: [PickleStep],
    tags: [PickleTag] = [],
    id: String = "pickle-1"
) -> Pickle {
    Pickle(
        id: id,
        uri: "test.feature",
        name: name,
        language: "en",
        tags: tags,
        steps: steps,
        astNodeIds: []
    )
}

private func makeStep(_ text: String, id: String = "step") -> PickleStep {
    PickleStep(id: id, text: text, argument: nil, astNodeIds: [])
}

private func noopDefinition(_ pattern: String) -> StepDefinition<ReporterTestFeature> {
    StepDefinition(
        pattern: .exact(pattern),
        sourceLocation: Location(line: 1),
        handler: { _, _, _ in }
    )
}

@Suite("Reporter Integration")
struct ReporterIntegrationTests {

    @Test("TestRunner sends events in correct order")
    func eventOrder() async throws {
        let tracker = EventTracker()
        let config = GherkinConfiguration(reporters: [tracker])
        let definitions = [noopDefinition("step A"), noopDefinition("step B")]
        let runner = TestRunner(definitions: definitions, configuration: config)

        let pickle = makePickle(
            name: "Login Scenario",
            steps: [
                makeStep("step A", id: "1"),
                makeStep("step B", id: "2")
            ])

        _ = try await runner.run(
            pickles: [pickle],
            featureName: "Login Feature",
            featureTags: [],
            feature: ReporterTestFeature()
        )

        let events = await tracker.events
        #expect(
            events == [
                "featureStarted:Login Feature",
                "scenarioStarted:Login Scenario",
                "stepFinished:step A",
                "stepFinished:step B",
                "scenarioFinished:Login Scenario",
                "featureFinished:Login Feature",
                "testRunFinished:1"
            ])
    }

    @Test("TestRunner sends events for multiple scenarios")
    func multipleScenarios() async throws {
        let tracker = EventTracker()
        let config = GherkinConfiguration(reporters: [tracker])
        let definitions = [noopDefinition("step")]
        let runner = TestRunner(definitions: definitions, configuration: config)

        let p1 = makePickle(name: "S1", steps: [makeStep("step")], id: "p1")
        let p2 = makePickle(name: "S2", steps: [makeStep("step")], id: "p2")

        _ = try await runner.run(
            pickles: [p1, p2],
            featureName: "F",
            featureTags: [],
            feature: ReporterTestFeature()
        )

        let events = await tracker.events
        #expect(events.contains("scenarioStarted:S1"))
        #expect(events.contains("scenarioFinished:S1"))
        #expect(events.contains("scenarioStarted:S2"))
        #expect(events.contains("scenarioFinished:S2"))
        #expect(events.contains("testRunFinished:2"))
    }

    @Test("TestRunner sends events for skipped scenarios (tag filter)")
    func skippedScenarioEvents() async throws {
        let tracker = EventTracker()
        let config = GherkinConfiguration(
            tagFilter: try TagFilter("@smoke"),
            reporters: [tracker]
        )
        let definitions = [noopDefinition("step")]
        let runner = TestRunner(definitions: definitions, configuration: config)

        let pickle = makePickle(
            name: "WIP Scenario",
            steps: [makeStep("step")],
            tags: [PickleTag(name: "@wip", astNodeId: "1")],
            id: "p1"
        )

        _ = try await runner.run(
            pickles: [pickle],
            featureName: "F",
            featureTags: [],
            feature: ReporterTestFeature()
        )

        let events = await tracker.events
        #expect(events.contains("scenarioStarted:WIP Scenario"))
        #expect(events.contains("scenarioFinished:WIP Scenario"))
    }

    @Test("CucumberJSONReporter produces valid JSON via TestRunner")
    func cucumberJSONIntegration() async throws {
        let reporter = CucumberJSONReporter()
        let config = GherkinConfiguration(reporters: [reporter])
        let definitions = [noopDefinition("login"), noopDefinition("see dashboard")]
        let runner = TestRunner(definitions: definitions, configuration: config)

        let pickle = makePickle(
            name: "Login",
            steps: [
                makeStep("login", id: "1"),
                makeStep("see dashboard", id: "2")
            ])

        _ = try await runner.run(
            pickles: [pickle],
            featureName: "Auth",
            featureTags: ["@smoke"],
            feature: ReporterTestFeature()
        )

        let data = try await reporter.generateReport()
        let json = try #require(String(data: data, encoding: .utf8))

        #expect(json.contains("\"name\" : \"Auth\""))
        #expect(json.contains("\"name\" : \"Login\""))
        #expect(json.contains("\"status\" : \"passed\""))
    }

    @Test("JUnitXMLReporter produces valid XML via TestRunner")
    func junitXMLIntegration() async throws {
        let reporter = JUnitXMLReporter()
        let config = GherkinConfiguration(reporters: [reporter])
        let definitions = [noopDefinition("step")]
        let runner = TestRunner(definitions: definitions, configuration: config)

        let pickle = makePickle(name: "S1", steps: [makeStep("step")])

        _ = try await runner.run(
            pickles: [pickle],
            featureName: "Feature A",
            featureTags: [],
            feature: ReporterTestFeature()
        )

        let data = try await reporter.generateReport()
        let xml = try #require(String(data: data, encoding: .utf8))

        #expect(xml.contains("<?xml"))
        #expect(xml.contains("<testsuites>"))
        #expect(xml.contains("Feature: Feature A"))
        #expect(xml.contains("Scenario: S1"))
    }

    @Test("HTMLReporter produces valid HTML via TestRunner")
    func htmlIntegration() async throws {
        let reporter = HTMLReporter()
        let config = GherkinConfiguration(reporters: [reporter])
        let definitions = [noopDefinition("step")]
        let runner = TestRunner(definitions: definitions, configuration: config)

        let pickle = makePickle(name: "S1", steps: [makeStep("step")])

        _ = try await runner.run(
            pickles: [pickle],
            featureName: "Feature B",
            featureTags: [],
            feature: ReporterTestFeature()
        )

        let data = try await reporter.generateReport()
        let html = try #require(String(data: data, encoding: .utf8))

        #expect(html.contains("<!DOCTYPE html>"))
        #expect(html.contains("Feature: Feature B"))
        #expect(html.contains("Scenario: S1"))
    }

    @Test("multiple reporters receive events simultaneously")
    func multipleReporters() async throws {
        let jsonReporter = CucumberJSONReporter()
        let xmlReporter = JUnitXMLReporter()
        let htmlReporter = HTMLReporter()
        let config = GherkinConfiguration(
            reporters: [jsonReporter, xmlReporter, htmlReporter]
        )
        let definitions = [noopDefinition("step")]
        let runner = TestRunner(definitions: definitions, configuration: config)

        let pickle = makePickle(name: "S1", steps: [makeStep("step")])

        _ = try await runner.run(
            pickles: [pickle],
            featureName: "Multi Reporter Feature",
            featureTags: [],
            feature: ReporterTestFeature()
        )

        let jsonData = try await jsonReporter.generateReport()
        let jsonText = try #require(String(data: jsonData, encoding: .utf8))
        #expect(jsonText.contains("Multi Reporter Feature"))

        let xmlData = try await xmlReporter.generateReport()
        let xmlText = try #require(String(data: xmlData, encoding: .utf8))
        #expect(xmlText.contains("Multi Reporter Feature"))

        let htmlData = try await htmlReporter.generateReport()
        let htmlText = try #require(String(data: htmlData, encoding: .utf8))
        #expect(htmlText.contains("Multi Reporter Feature"))
    }

    @Test("writeReport(to:) writes report to disk and creates directories")
    func writeReportToDisk() async throws {
        let reporter = CucumberJSONReporter()
        let pickleStep = PickleStep(id: "s1", text: "login", argument: nil, astNodeIds: [])
        let step = StepResult(step: pickleStep, status: .passed, duration: .milliseconds(10), location: Location(line: 1))
        let scenario = ScenarioResult(name: "S1", stepResults: [step], tags: [])
        let feature = FeatureResult(name: "F1", scenarioResults: [scenario], tags: [])
        let result = TestRunResult(featureResults: [feature], duration: .seconds(1))

        await reporter.testRunFinished(result)

        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("gherkin-test-\(ProcessInfo.processInfo.globallyUniqueString)")
        let fileURL =
            tempDir
            .appendingPathComponent("nested/report.json")

        try await reporter.writeReport(to: fileURL)

        let data = try Data(contentsOf: fileURL)
        let json = try #require(String(data: data, encoding: .utf8))
        #expect(json.contains("\"name\" : \"F1\""))

        try FileManager.default.removeItem(at: tempDir)
    }

    @Test("empty test run produces valid reports from all reporters")
    func emptyRunReports() async throws {
        let jsonReporter = CucumberJSONReporter()
        let xmlReporter = JUnitXMLReporter()
        let htmlReporter = HTMLReporter()
        let config = GherkinConfiguration(
            reporters: [jsonReporter, xmlReporter, htmlReporter]
        )
        let runner = TestRunner<ReporterTestFeature>(
            definitions: [],
            configuration: config
        )

        _ = try await runner.run(
            pickles: [],
            featureName: "Empty",
            featureTags: [],
            feature: ReporterTestFeature()
        )

        let jsonData = try await jsonReporter.generateReport()
        #expect(jsonData.count > 0)

        let xmlData = try await xmlReporter.generateReport()
        let xmlText = try #require(String(data: xmlData, encoding: .utf8))
        #expect(xmlText.contains("<testsuites>"))

        let htmlData = try await htmlReporter.generateReport()
        let htmlText = try #require(String(data: htmlData, encoding: .utf8))
        #expect(htmlText.contains("<!DOCTYPE html>"))
    }
}
