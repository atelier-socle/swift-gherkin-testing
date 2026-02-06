// JUnitXMLReporterTests.swift
// GherkinTestingTests
//
// Copyright © 2026 Atelier Socle. MIT License.

import Foundation
import Testing

@testable import GherkinTesting

// MARK: - Test Helpers

private func makePickleStep(_ text: String, id: String = "step-1") -> PickleStep {
    PickleStep(id: id, text: text, argument: nil, astNodeIds: [])
}

private func makeStepResult(
    text: String,
    status: StepStatus = .passed,
    duration: Duration = .milliseconds(100),
    location: Location? = Location(line: 10)
) -> StepResult {
    StepResult(
        step: makePickleStep(text),
        status: status,
        duration: duration,
        location: location
    )
}

private func makeScenarioResult(
    name: String = "Test Scenario",
    stepResults: [StepResult] = [],
    tags: [String] = []
) -> ScenarioResult {
    ScenarioResult(name: name, stepResults: stepResults, tags: tags)
}

private func makeFeatureResult(
    name: String = "Test Feature",
    scenarioResults: [ScenarioResult] = [],
    tags: [String] = []
) -> FeatureResult {
    FeatureResult(name: name, scenarioResults: scenarioResults, tags: tags)
}

private func makeTestRunResult(
    featureResults: [FeatureResult] = [],
    duration: Duration = .seconds(1)
) -> TestRunResult {
    TestRunResult(featureResults: featureResults, duration: duration)
}

@Suite("JUnitXMLReporter")
struct JUnitXMLReporterTests {

    // MARK: - Basic Structure

    @Test("generates valid XML declaration")
    func xmlDeclaration() async throws {
        let reporter = JUnitXMLReporter()
        let data = try await reporter.generateReport()
        let xml = try #require(String(data: data, encoding: .utf8))

        #expect(xml.contains("<?xml version=\"1.0\" encoding=\"UTF-8\"?>"))
    }

    @Test("generates testsuites root element")
    func testSuitesRoot() async throws {
        let reporter = JUnitXMLReporter()
        let data = try await reporter.generateReport()
        let xml = try #require(String(data: data, encoding: .utf8))

        #expect(xml.contains("<testsuites>"))
        #expect(xml.contains("</testsuites>"))
    }

    @Test("empty result generates empty testsuites")
    func emptyReport() async throws {
        let reporter = JUnitXMLReporter()
        let result = makeTestRunResult()
        await reporter.testRunFinished(result)
        let data = try await reporter.generateReport()
        let xml = try #require(String(data: data, encoding: .utf8))

        #expect(xml.contains("<testsuites>"))
        #expect(xml.contains("</testsuites>"))
    }

    // MARK: - Test Suite (Feature)

    @Test("testsuite has correct attributes")
    func testSuiteAttributes() async throws {
        let reporter = JUnitXMLReporter()
        let step = makeStepResult(text: "step", duration: .milliseconds(500))
        let s1 = makeScenarioResult(name: "S1", stepResults: [step])
        let s2 = makeScenarioResult(
            name: "S2",
            stepResults: [
                makeStepResult(text: "fail", status: .failed(StepFailure(message: "err")))
            ])
        let s3 = makeScenarioResult(
            name: "S3",
            stepResults: [
                makeStepResult(text: "skip", status: .skipped)
            ])
        let feature = makeFeatureResult(
            name: "Login",
            scenarioResults: [s1, s2, s3]
        )
        let result = makeTestRunResult(featureResults: [feature])

        await reporter.testRunFinished(result)
        let data = try await reporter.generateReport()
        let xml = try #require(String(data: data, encoding: .utf8))

        #expect(xml.contains("name=\"Feature: Login\""))
        #expect(xml.contains("tests=\"3\""))
        #expect(xml.contains("failures=\"1\""))
        #expect(xml.contains("errors=\"0\""))
        #expect(xml.contains("skipped=\"1\""))
        #expect(xml.contains("time=\""))
    }

    @Test("multiple features generate multiple testsuites")
    func multipleFeatures() async throws {
        let reporter = JUnitXMLReporter()
        let f1 = makeFeatureResult(name: "Login")
        let f2 = makeFeatureResult(name: "Registration")
        let result = makeTestRunResult(featureResults: [f1, f2])

        await reporter.testRunFinished(result)
        let data = try await reporter.generateReport()
        let xml = try #require(String(data: data, encoding: .utf8))

        #expect(xml.contains("name=\"Feature: Login\""))
        #expect(xml.contains("name=\"Feature: Registration\""))
    }

    // MARK: - Test Case (Scenario)

    @Test("testcase has name, classname, and time")
    func testCaseAttributes() async throws {
        let reporter = JUnitXMLReporter()
        let step = makeStepResult(text: "step", duration: .milliseconds(456))
        let scenario = makeScenarioResult(name: "Successful login", stepResults: [step])
        let feature = makeFeatureResult(name: "Login", scenarioResults: [scenario])
        let result = makeTestRunResult(featureResults: [feature])

        await reporter.testRunFinished(result)
        let data = try await reporter.generateReport()
        let xml = try #require(String(data: data, encoding: .utf8))

        #expect(xml.contains("name=\"Scenario: Successful login\""))
        #expect(xml.contains("classname=\"Login\""))
        #expect(xml.contains("time=\"0.456\""))
    }

    @Test("passed testcase is self-closing")
    func passedTestCase() async throws {
        let reporter = JUnitXMLReporter()
        let step = makeStepResult(text: "step")
        let scenario = makeScenarioResult(stepResults: [step])
        let feature = makeFeatureResult(scenarioResults: [scenario])
        let result = makeTestRunResult(featureResults: [feature])

        await reporter.testRunFinished(result)
        let data = try await reporter.generateReport()
        let xml = try #require(String(data: data, encoding: .utf8))

        #expect(xml.contains("/>"))
    }

    // MARK: - Failures

    @Test("failed testcase has failure element")
    func failedTestCase() async throws {
        let reporter = JUnitXMLReporter()
        let step = makeStepResult(
            text: "they see dashboard",
            status: .failed(StepFailure(message: "Expected dashboard"))
        )
        let scenario = makeScenarioResult(name: "Failed login", stepResults: [step])
        let feature = makeFeatureResult(name: "Login", scenarioResults: [scenario])
        let result = makeTestRunResult(featureResults: [feature])

        await reporter.testRunFinished(result)
        let data = try await reporter.generateReport()
        let xml = try #require(String(data: data, encoding: .utf8))

        #expect(xml.contains("<failure"))
        #expect(xml.contains("message=\"Expected dashboard\""))
        #expect(xml.contains("type=\"StepFailure\""))
        #expect(xml.contains("</failure>"))
    }

    @Test("ambiguous testcase has failure element")
    func ambiguousTestCase() async throws {
        let reporter = JUnitXMLReporter()
        let step = makeStepResult(text: "ambiguous step", status: .ambiguous)
        let scenario = makeScenarioResult(stepResults: [step])
        let feature = makeFeatureResult(scenarioResults: [scenario])
        let result = makeTestRunResult(featureResults: [feature])

        await reporter.testRunFinished(result)
        let data = try await reporter.generateReport()
        let xml = try #require(String(data: data, encoding: .utf8))

        #expect(xml.contains("<failure"))
        #expect(xml.contains("AmbiguousStepError"))
    }

    // MARK: - Skipped

    @Test("skipped testcase has skipped element")
    func skippedTestCase() async throws {
        let reporter = JUnitXMLReporter()
        let step = makeStepResult(text: "step", status: .skipped)
        let scenario = makeScenarioResult(stepResults: [step])
        let feature = makeFeatureResult(scenarioResults: [scenario])
        let result = makeTestRunResult(featureResults: [feature])

        await reporter.testRunFinished(result)
        let data = try await reporter.generateReport()
        let xml = try #require(String(data: data, encoding: .utf8))

        #expect(xml.contains("<skipped/>"))
    }

    @Test("pending testcase has skipped element with message")
    func pendingTestCase() async throws {
        let reporter = JUnitXMLReporter()
        let step = makeStepResult(text: "step", status: .pending)
        let scenario = makeScenarioResult(stepResults: [step])
        let feature = makeFeatureResult(scenarioResults: [scenario])
        let result = makeTestRunResult(featureResults: [feature])

        await reporter.testRunFinished(result)
        let data = try await reporter.generateReport()
        let xml = try #require(String(data: data, encoding: .utf8))

        #expect(xml.contains("skipped message=\"pending\""))
    }

    @Test("undefined testcase has skipped element with message")
    func undefinedTestCase() async throws {
        let reporter = JUnitXMLReporter()
        let step = makeStepResult(text: "step", status: .undefined)
        let scenario = makeScenarioResult(stepResults: [step])
        let feature = makeFeatureResult(scenarioResults: [scenario])
        let result = makeTestRunResult(featureResults: [feature])

        await reporter.testRunFinished(result)
        let data = try await reporter.generateReport()
        let xml = try #require(String(data: data, encoding: .utf8))

        #expect(xml.contains("skipped message=\"undefined\""))
    }

    // MARK: - XML Escaping

    @Test("XML special characters are escaped")
    func xmlEscaping() async throws {
        let reporter = JUnitXMLReporter()
        let step = makeStepResult(text: "value <\"test\"> & 'more'")
        let scenario = makeScenarioResult(
            name: "User's <special> & \"test\"",
            stepResults: [step]
        )
        let feature = makeFeatureResult(
            name: "Feature & <Test>",
            scenarioResults: [scenario]
        )
        let result = makeTestRunResult(featureResults: [feature])

        await reporter.testRunFinished(result)
        let data = try await reporter.generateReport()
        let xml = try #require(String(data: data, encoding: .utf8))

        // Feature name escaping
        #expect(xml.contains("Feature &amp; &lt;Test&gt;"))
        // Scenario name escaping (all 5 special chars)
        #expect(xml.contains("&amp;"))
        #expect(xml.contains("&lt;"))
        #expect(xml.contains("&gt;"))
        #expect(xml.contains("&quot;"))
        #expect(xml.contains("&apos;"))
    }

    // MARK: - Duration Format

    @Test("duration is formatted as seconds with three decimal places")
    func durationFormat() async throws {
        let reporter = JUnitXMLReporter()
        let step = makeStepResult(text: "step", duration: .milliseconds(1234))
        let scenario = makeScenarioResult(stepResults: [step])
        let feature = makeFeatureResult(scenarioResults: [scenario])
        let result = makeTestRunResult(featureResults: [feature])

        await reporter.testRunFinished(result)
        let data = try await reporter.generateReport()
        let xml = try #require(String(data: data, encoding: .utf8))

        #expect(xml.contains("time=\"1.234\""))
    }
}
