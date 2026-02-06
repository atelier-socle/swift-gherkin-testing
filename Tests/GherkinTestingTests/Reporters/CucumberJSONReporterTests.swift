// CucumberJSONReporterTests.swift
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

@Suite("CucumberJSONReporter")
struct CucumberJSONReporterTests {

    // MARK: - Basic Report Generation

    @Test("generates valid empty JSON array when no data")
    func emptyReport() async throws {
        let reporter = CucumberJSONReporter()
        let data = try await reporter.generateReport()
        let json = try #require(String(data: data, encoding: .utf8))
        #expect(json.contains("["))
        #expect(json.contains("]"))
    }

    @Test("generates valid JSON parsable by JSONDecoder")
    func validJSONOutput() async throws {
        let reporter = CucumberJSONReporter()
        let step = makeStepResult(text: "the user is logged in")
        let scenario = makeScenarioResult(
            name: "Successful login",
            stepResults: [step],
            tags: ["@smoke"]
        )
        let feature = makeFeatureResult(
            name: "Login",
            scenarioResults: [scenario],
            tags: ["@regression"]
        )
        let result = makeTestRunResult(featureResults: [feature])

        await reporter.testRunFinished(result)
        let data = try await reporter.generateReport()

        // Validate it's parsable by JSONDecoder
        let decoded = try JSONDecoder().decode(
            [CucumberJSONReporter.CucumberFeature].self,
            from: data
        )
        #expect(decoded.count == 1)
        #expect(decoded[0].name == "Login")
        #expect(decoded[0].elements.count == 1)
        #expect(decoded[0].elements[0].name == "Successful login")
    }

    // MARK: - Feature Structure

    @Test("feature contains keyword, name, id, and elements")
    func featureStructure() async throws {
        let reporter = CucumberJSONReporter()
        let scenario = makeScenarioResult(name: "S1")
        let feature = makeFeatureResult(name: "Login Feature", scenarioResults: [scenario])
        let result = makeTestRunResult(featureResults: [feature])

        await reporter.testRunFinished(result)
        let data = try await reporter.generateReport()
        let json = try #require(String(data: data, encoding: .utf8))

        #expect(json.contains("\"keyword\" : \"Feature\""))
        #expect(json.contains("\"name\" : \"Login Feature\""))
        #expect(json.contains("\"id\" : \"login-feature\""))
        #expect(json.contains("\"elements\""))
    }

    @Test("feature tags are included")
    func featureTags() async throws {
        let reporter = CucumberJSONReporter()
        let feature = makeFeatureResult(
            name: "Tagged",
            tags: ["@smoke", "@regression"]
        )
        let result = makeTestRunResult(featureResults: [feature])

        await reporter.testRunFinished(result)
        let data = try await reporter.generateReport()
        let json = try #require(String(data: data, encoding: .utf8))

        #expect(json.contains("@smoke"))
        #expect(json.contains("@regression"))
    }

    // MARK: - Scenario Structure

    @Test("scenario contains keyword, name, id, type, and steps")
    func scenarioStructure() async throws {
        let reporter = CucumberJSONReporter()
        let step = makeStepResult(text: "something happens")
        let scenario = makeScenarioResult(
            name: "Successful login",
            stepResults: [step]
        )
        let feature = makeFeatureResult(scenarioResults: [scenario])
        let result = makeTestRunResult(featureResults: [feature])

        await reporter.testRunFinished(result)
        let data = try await reporter.generateReport()
        let json = try #require(String(data: data, encoding: .utf8))

        #expect(json.contains("\"keyword\" : \"Scenario\""))
        #expect(json.contains("\"name\" : \"Successful login\""))
        #expect(json.contains("\"type\" : \"scenario\""))
        #expect(json.contains("\"steps\""))
    }

    @Test("scenario tags are included")
    func scenarioTags() async throws {
        let reporter = CucumberJSONReporter()
        let scenario = makeScenarioResult(tags: ["@wip", "@slow"])
        let feature = makeFeatureResult(scenarioResults: [scenario])
        let result = makeTestRunResult(featureResults: [feature])

        await reporter.testRunFinished(result)
        let data = try await reporter.generateReport()
        let json = try #require(String(data: data, encoding: .utf8))

        #expect(json.contains("@wip"))
        #expect(json.contains("@slow"))
    }

    @Test("scenario has before and after arrays")
    func scenarioHookArrays() async throws {
        let reporter = CucumberJSONReporter()
        let scenario = makeScenarioResult()
        let feature = makeFeatureResult(scenarioResults: [scenario])
        let result = makeTestRunResult(featureResults: [feature])

        await reporter.testRunFinished(result)
        let data = try await reporter.generateReport()
        let json = try #require(String(data: data, encoding: .utf8))

        #expect(json.contains("\"before\""))
        #expect(json.contains("\"after\""))
    }

    // MARK: - Step Structure

    @Test("step contains keyword, name, match, and result")
    func stepStructure() async throws {
        let reporter = CucumberJSONReporter()
        let step = makeStepResult(text: "the user clicks login", location: Location(line: 15))
        let scenario = makeScenarioResult(stepResults: [step])
        let feature = makeFeatureResult(scenarioResults: [scenario])
        let result = makeTestRunResult(featureResults: [feature])

        await reporter.testRunFinished(result)
        let data = try await reporter.generateReport()
        let json = try #require(String(data: data, encoding: .utf8))

        #expect(json.contains("\"keyword\" : \"Step \""))
        #expect(json.contains("\"name\" : \"the user clicks login\""))
        #expect(json.contains("\"match\""))
        #expect(json.contains("\"location\" : \"step:15\""))
        #expect(json.contains("\"result\""))
    }

    // MARK: - Status Mapping

    @Test("passed status maps correctly")
    func passedStatus() async throws {
        let reporter = CucumberJSONReporter()
        let step = makeStepResult(text: "step", status: .passed)
        let scenario = makeScenarioResult(stepResults: [step])
        let feature = makeFeatureResult(scenarioResults: [scenario])

        await reporter.testRunFinished(makeTestRunResult(featureResults: [feature]))
        let data = try await reporter.generateReport()
        let json = try #require(String(data: data, encoding: .utf8))

        #expect(json.contains("\"status\" : \"passed\""))
    }

    @Test("failed status maps correctly with error_message")
    func failedStatus() async throws {
        let reporter = CucumberJSONReporter()
        let step = makeStepResult(
            text: "step",
            status: .failed(StepFailure(message: "Expected true"))
        )
        let scenario = makeScenarioResult(stepResults: [step])
        let feature = makeFeatureResult(scenarioResults: [scenario])

        await reporter.testRunFinished(makeTestRunResult(featureResults: [feature]))
        let data = try await reporter.generateReport()
        let json = try #require(String(data: data, encoding: .utf8))

        #expect(json.contains("\"status\" : \"failed\""))
        #expect(json.contains("\"error_message\" : \"Expected true\""))
    }

    @Test("skipped status maps correctly")
    func skippedStatus() async throws {
        let reporter = CucumberJSONReporter()
        let step = makeStepResult(text: "step", status: .skipped)
        let scenario = makeScenarioResult(stepResults: [step])
        let feature = makeFeatureResult(scenarioResults: [scenario])

        await reporter.testRunFinished(makeTestRunResult(featureResults: [feature]))
        let data = try await reporter.generateReport()
        let json = try #require(String(data: data, encoding: .utf8))

        #expect(json.contains("\"status\" : \"skipped\""))
    }

    @Test("pending status maps correctly")
    func pendingStatus() async throws {
        let reporter = CucumberJSONReporter()
        let step = makeStepResult(text: "step", status: .pending)
        let scenario = makeScenarioResult(stepResults: [step])
        let feature = makeFeatureResult(scenarioResults: [scenario])

        await reporter.testRunFinished(makeTestRunResult(featureResults: [feature]))
        let data = try await reporter.generateReport()
        let json = try #require(String(data: data, encoding: .utf8))

        #expect(json.contains("\"status\" : \"pending\""))
    }

    @Test("undefined status maps correctly")
    func undefinedStatus() async throws {
        let reporter = CucumberJSONReporter()
        let step = makeStepResult(text: "step", status: .undefined)
        let scenario = makeScenarioResult(stepResults: [step])
        let feature = makeFeatureResult(scenarioResults: [scenario])

        await reporter.testRunFinished(makeTestRunResult(featureResults: [feature]))
        let data = try await reporter.generateReport()
        let json = try #require(String(data: data, encoding: .utf8))

        #expect(json.contains("\"status\" : \"undefined\""))
    }

    @Test("ambiguous status maps correctly")
    func ambiguousStatus() async throws {
        let reporter = CucumberJSONReporter()
        let step = makeStepResult(text: "step", status: .ambiguous)
        let scenario = makeScenarioResult(stepResults: [step])
        let feature = makeFeatureResult(scenarioResults: [scenario])

        await reporter.testRunFinished(makeTestRunResult(featureResults: [feature]))
        let data = try await reporter.generateReport()
        let json = try #require(String(data: data, encoding: .utf8))

        #expect(json.contains("\"status\" : \"ambiguous\""))
    }

    // MARK: - Duration

    @Test("duration is in nanoseconds")
    func durationInNanoseconds() async throws {
        let reporter = CucumberJSONReporter()
        // 1.5 seconds = 1_500_000_000 nanoseconds
        let step = makeStepResult(text: "step", duration: .milliseconds(1500))
        let scenario = makeScenarioResult(stepResults: [step])
        let feature = makeFeatureResult(scenarioResults: [scenario])

        await reporter.testRunFinished(makeTestRunResult(featureResults: [feature]))
        let data = try await reporter.generateReport()
        let json = try #require(String(data: data, encoding: .utf8))

        #expect(json.contains("1500000000"))
    }

    // MARK: - Multiple Features and Scenarios

    @Test("multiple features are included")
    func multipleFeatures() async throws {
        let reporter = CucumberJSONReporter()
        let feature1 = makeFeatureResult(name: "Login")
        let feature2 = makeFeatureResult(name: "Registration")
        let result = makeTestRunResult(featureResults: [feature1, feature2])

        await reporter.testRunFinished(result)
        let data = try await reporter.generateReport()
        let json = try #require(String(data: data, encoding: .utf8))

        #expect(json.contains("\"name\" : \"Login\""))
        #expect(json.contains("\"name\" : \"Registration\""))

        let decoded = try JSONDecoder().decode(
            [CucumberJSONReporter.CucumberFeature].self,
            from: data
        )
        #expect(decoded.count == 2)
    }

    @Test("multiple scenarios in a feature")
    func multipleScenarios() async throws {
        let reporter = CucumberJSONReporter()
        let s1 = makeScenarioResult(name: "Scenario A")
        let s2 = makeScenarioResult(name: "Scenario B")
        let feature = makeFeatureResult(scenarioResults: [s1, s2])
        let result = makeTestRunResult(featureResults: [feature])

        await reporter.testRunFinished(result)
        let data = try await reporter.generateReport()
        let json = try #require(String(data: data, encoding: .utf8))

        #expect(json.contains("\"name\" : \"Scenario A\""))
        #expect(json.contains("\"name\" : \"Scenario B\""))
    }

    @Test("multiple steps in a scenario")
    func multipleSteps() async throws {
        let reporter = CucumberJSONReporter()
        let steps = [
            makeStepResult(text: "the user opens the app"),
            makeStepResult(text: "they tap login"),
            makeStepResult(text: "they see the dashboard")
        ]
        let scenario = makeScenarioResult(stepResults: steps)
        let feature = makeFeatureResult(scenarioResults: [scenario])
        let result = makeTestRunResult(featureResults: [feature])

        await reporter.testRunFinished(result)
        let data = try await reporter.generateReport()
        let json = try #require(String(data: data, encoding: .utf8))

        #expect(json.contains("the user opens the app"))
        #expect(json.contains("they tap login"))
        #expect(json.contains("they see the dashboard"))
    }
}
