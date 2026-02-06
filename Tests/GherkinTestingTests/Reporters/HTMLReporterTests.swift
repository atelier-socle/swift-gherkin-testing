// HTMLReporterTests.swift
// GherkinTestingTests
//
// Copyright © 2026 Atelier Socle. MIT License.

import Testing
import Foundation
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

@Suite("HTMLReporter")
struct HTMLReporterTests {

    // MARK: - Basic HTML Structure

    @Test("generates valid HTML document")
    func validHTML() async throws {
        let reporter = HTMLReporter()
        let data = try await reporter.generateReport()
        let html = try #require(String(data: data, encoding: .utf8))

        #expect(html.contains("<!DOCTYPE html>"))
        #expect(html.contains("<html"))
        #expect(html.contains("</html>"))
        #expect(html.contains("<head>"))
        #expect(html.contains("</head>"))
        #expect(html.contains("<body>"))
        #expect(html.contains("</body>"))
    }

    @Test("includes title")
    func includesTitle() async throws {
        let reporter = HTMLReporter()
        let data = try await reporter.generateReport()
        let html = try #require(String(data: data, encoding: .utf8))

        #expect(html.contains("<title>Gherkin Test Report</title>"))
    }

    @Test("includes inline CSS")
    func includesInlineCSS() async throws {
        let reporter = HTMLReporter()
        let data = try await reporter.generateReport()
        let html = try #require(String(data: data, encoding: .utf8))

        #expect(html.contains("<style>"))
        #expect(html.contains("</style>"))
        #expect(html.contains("--passed"))
        #expect(html.contains("--failed"))
        #expect(html.contains("--skipped"))
        #expect(html.contains("--pending"))
        #expect(html.contains("--undefined"))
    }

    @Test("includes inline JavaScript")
    func includesInlineJS() async throws {
        let reporter = HTMLReporter()
        let data = try await reporter.generateReport()
        let html = try #require(String(data: data, encoding: .utf8))

        #expect(html.contains("<script>"))
        #expect(html.contains("</script>"))
        #expect(html.contains("toggleFeature"))
        #expect(html.contains("toggleScenario"))
        #expect(html.contains("applyFilters"))
    }

    @Test("includes dark mode support")
    func darkModeSupport() async throws {
        let reporter = HTMLReporter()
        let data = try await reporter.generateReport()
        let html = try #require(String(data: data, encoding: .utf8))

        #expect(html.contains("prefers-color-scheme: dark"))
    }

    @Test("includes responsive meta viewport")
    func responsiveViewport() async throws {
        let reporter = HTMLReporter()
        let data = try await reporter.generateReport()
        let html = try #require(String(data: data, encoding: .utf8))

        #expect(html.contains("viewport"))
        #expect(html.contains("width=device-width"))
    }

    // MARK: - Summary Dashboard

    @Test("summary shows correct counts")
    func summaryCounts() async throws {
        let reporter = HTMLReporter()
        let passedStep = makeStepResult(text: "ok")
        let failedStep = makeStepResult(
            text: "fail",
            status: .failed(StepFailure(message: "err"))
        )
        let skippedStep = makeStepResult(text: "skip", status: .skipped)

        let s1 = makeScenarioResult(name: "S1", stepResults: [passedStep])
        let s2 = makeScenarioResult(name: "S2", stepResults: [failedStep])
        let s3 = makeScenarioResult(name: "S3", stepResults: [skippedStep])
        let feature = makeFeatureResult(scenarioResults: [s1, s2, s3])
        let result = makeTestRunResult(featureResults: [feature])

        await reporter.testRunFinished(result)
        let data = try await reporter.generateReport()
        let html = try #require(String(data: data, encoding: .utf8))

        #expect(html.contains("class=\"summary\""))
        #expect(html.contains("Total"))
        #expect(html.contains("Passed"))
        #expect(html.contains("Failed"))
        #expect(html.contains("Skipped"))
        #expect(html.contains("Pass Rate"))
        #expect(html.contains("Duration"))
    }

    @Test("summary dashboard has grid layout")
    func summaryGrid() async throws {
        let reporter = HTMLReporter()
        let data = try await reporter.generateReport()
        let html = try #require(String(data: data, encoding: .utf8))

        #expect(html.contains("summary-grid"))
        #expect(html.contains("summary-card"))
    }

    // MARK: - Status Filters

    @Test("includes status filter buttons")
    func statusFilters() async throws {
        let reporter = HTMLReporter()
        let data = try await reporter.generateReport()
        let html = try #require(String(data: data, encoding: .utf8))

        #expect(html.contains("data-status=\"all\""))
        #expect(html.contains("data-status=\"passed\""))
        #expect(html.contains("data-status=\"failed\""))
        #expect(html.contains("data-status=\"skipped\""))
        #expect(html.contains("data-status=\"pending\""))
        #expect(html.contains("data-status=\"undefined\""))
    }

    // MARK: - Tag Filter

    @Test("includes tag filter dropdown when tags present")
    func tagFilterDropdown() async throws {
        let reporter = HTMLReporter()
        let scenario = makeScenarioResult(tags: ["@smoke", "@login"])
        let feature = makeFeatureResult(scenarioResults: [scenario])
        let result = makeTestRunResult(featureResults: [feature])

        await reporter.testRunFinished(result)
        let data = try await reporter.generateReport()
        let html = try #require(String(data: data, encoding: .utf8))

        #expect(html.contains("tag-filter"))
        #expect(html.contains("@smoke"))
        #expect(html.contains("@login"))
        #expect(html.contains("All Tags"))
    }

    // MARK: - Feature Display

    @Test("features are displayed with names")
    func featureDisplay() async throws {
        let reporter = HTMLReporter()
        let scenario = makeScenarioResult(stepResults: [makeStepResult(text: "ok")])
        let feature = makeFeatureResult(name: "Login Feature", scenarioResults: [scenario])
        let result = makeTestRunResult(featureResults: [feature])

        await reporter.testRunFinished(result)
        let data = try await reporter.generateReport()
        let html = try #require(String(data: data, encoding: .utf8))

        #expect(html.contains("Feature: Login Feature"))
        #expect(html.contains("class=\"feature\""))
        #expect(html.contains("feature-header"))
    }

    @Test("features have collapse/expand toggle")
    func featureToggle() async throws {
        let reporter = HTMLReporter()
        let feature = makeFeatureResult(name: "F1")
        let result = makeTestRunResult(featureResults: [feature])

        await reporter.testRunFinished(result)
        let data = try await reporter.generateReport()
        let html = try #require(String(data: data, encoding: .utf8))

        #expect(html.contains("toggle-icon"))
        #expect(html.contains("onclick"))
    }

    // MARK: - Scenario Display

    @Test("scenarios are displayed with names and status")
    func scenarioDisplay() async throws {
        let reporter = HTMLReporter()
        let step = makeStepResult(text: "ok")
        let scenario = makeScenarioResult(name: "Successful login", stepResults: [step])
        let feature = makeFeatureResult(scenarioResults: [scenario])
        let result = makeTestRunResult(featureResults: [feature])

        await reporter.testRunFinished(result)
        let data = try await reporter.generateReport()
        let html = try #require(String(data: data, encoding: .utf8))

        #expect(html.contains("Scenario: Successful login"))
        #expect(html.contains("class=\"scenario\""))
        #expect(html.contains("data-status=\"passed\""))
    }

    // MARK: - Step Display

    @Test("steps are displayed with text and status classes")
    func stepDisplay() async throws {
        let reporter = HTMLReporter()
        let passedStep = makeStepResult(text: "user is logged in")
        let failedStep = makeStepResult(
            text: "sees dashboard",
            status: .failed(StepFailure(message: "Not found"))
        )
        let scenario = makeScenarioResult(stepResults: [passedStep, failedStep])
        let feature = makeFeatureResult(scenarioResults: [scenario])
        let result = makeTestRunResult(featureResults: [feature])

        await reporter.testRunFinished(result)
        let data = try await reporter.generateReport()
        let html = try #require(String(data: data, encoding: .utf8))

        #expect(html.contains("user is logged in"))
        #expect(html.contains("sees dashboard"))
        #expect(html.contains("class=\"step passed\""))
        #expect(html.contains("class=\"step failed\""))
    }

    @Test("failed steps show error message")
    func failedStepError() async throws {
        let reporter = HTMLReporter()
        let step = makeStepResult(
            text: "step fails",
            status: .failed(StepFailure(message: "Expected true but got false"))
        )
        let scenario = makeScenarioResult(stepResults: [step])
        let feature = makeFeatureResult(scenarioResults: [scenario])
        let result = makeTestRunResult(featureResults: [feature])

        await reporter.testRunFinished(result)
        let data = try await reporter.generateReport()
        let html = try #require(String(data: data, encoding: .utf8))

        #expect(html.contains("error-message"))
        #expect(html.contains("Expected true but got false"))
    }

    // MARK: - Tags Display

    @Test("tags are displayed as badges")
    func tagBadges() async throws {
        let reporter = HTMLReporter()
        let scenario = makeScenarioResult(tags: ["@smoke", "@login"])
        let feature = makeFeatureResult(
            scenarioResults: [scenario],
            tags: ["@regression"]
        )
        let result = makeTestRunResult(featureResults: [feature])

        await reporter.testRunFinished(result)
        let data = try await reporter.generateReport()
        let html = try #require(String(data: data, encoding: .utf8))

        #expect(html.contains("tag-badge"))
        #expect(html.contains("@smoke"))
        #expect(html.contains("@login"))
        #expect(html.contains("@regression"))
    }

    // MARK: - Duration Display

    @Test("durations are displayed on features and scenarios")
    func durationDisplay() async throws {
        let reporter = HTMLReporter()
        let step = makeStepResult(text: "step", duration: .seconds(2))
        let scenario = makeScenarioResult(stepResults: [step])
        let feature = makeFeatureResult(scenarioResults: [scenario])
        let result = makeTestRunResult(featureResults: [feature])

        await reporter.testRunFinished(result)
        let data = try await reporter.generateReport()
        let html = try #require(String(data: data, encoding: .utf8))

        #expect(html.contains("class=\"duration\""))
    }

    // MARK: - Status Badges

    @Test("status badges have correct CSS classes")
    func statusBadgeClasses() async throws {
        let reporter = HTMLReporter()
        let steps: [StepResult] = [
            makeStepResult(text: "ok", status: .passed),
            makeStepResult(text: "fail", status: .failed(StepFailure(message: "err"))),
            makeStepResult(text: "skip", status: .skipped),
            makeStepResult(text: "pend", status: .pending),
            makeStepResult(text: "undef", status: .undefined),
        ]
        let scenarios = steps.enumerated().map { i, step in
            makeScenarioResult(name: "S\(i)", stepResults: [step])
        }
        let feature = makeFeatureResult(scenarioResults: scenarios)
        let result = makeTestRunResult(featureResults: [feature])

        await reporter.testRunFinished(result)
        let data = try await reporter.generateReport()
        let html = try #require(String(data: data, encoding: .utf8))

        #expect(html.contains("status-badge passed"))
        #expect(html.contains("status-badge failed"))
        #expect(html.contains("status-badge skipped"))
        #expect(html.contains("status-badge pending"))
        #expect(html.contains("status-badge undefined"))
    }

    // MARK: - Empty Report

    @Test("empty report under 50KB")
    func emptyReportSize() async throws {
        let reporter = HTMLReporter()
        let data = try await reporter.generateReport()
        #expect(data.count < 50_000)
    }
}
