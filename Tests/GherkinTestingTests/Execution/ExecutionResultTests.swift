// ExecutionResultTests.swift
// GherkinTestingTests
//
// Copyright © 2026 Atelier Socle. MIT License.

import Testing

@testable import GherkinTesting

/// Helper to create a PickleStep for result tests.
private func step(_ text: String) -> PickleStep {
    PickleStep(id: "s-\(text)", text: text, argument: nil, astNodeIds: [])
}

@Suite("ExecutionResult")
struct ExecutionResultTests {

    // MARK: - StepFailure

    @Test("StepFailure from message")
    func stepFailureFromMessage() {
        let failure = StepFailure(message: "something went wrong")
        #expect(failure.message == "something went wrong")
    }

    @Test("StepFailure from error")
    func stepFailureFromError() {
        struct TestError: Error, CustomStringConvertible {
            var description: String { "test error" }
        }
        let failure = StepFailure(error: TestError())
        #expect(failure.message == "test error")
    }

    @Test("StepFailure is equatable")
    func stepFailureEquatable() {
        let a = StepFailure(message: "fail")
        let b = StepFailure(message: "fail")
        let c = StepFailure(message: "other")
        #expect(a == b)
        #expect(a != c)
    }

    // MARK: - StepStatus

    @Test("StepStatus priority ordering")
    func statusPriority() {
        #expect(StepStatus.passed.priority < StepStatus.skipped.priority)
        #expect(StepStatus.skipped.priority < StepStatus.pending.priority)
        #expect(StepStatus.pending.priority < StepStatus.undefined.priority)
        #expect(StepStatus.undefined.priority < StepStatus.ambiguous.priority)
        #expect(StepStatus.ambiguous.priority < StepStatus.failed(StepFailure(message: "")).priority)
    }

    @Test("isFailure for various statuses")
    func isFailure() {
        #expect(!StepStatus.passed.isFailure)
        #expect(StepStatus.skipped.isFailure)
        #expect(StepStatus.pending.isFailure)
        #expect(StepStatus.undefined.isFailure)
        #expect(StepStatus.ambiguous.isFailure)
        #expect(StepStatus.failed(StepFailure(message: "")).isFailure)
    }

    @Test("StepStatus is equatable")
    func statusEquatable() {
        #expect(StepStatus.passed == StepStatus.passed)
        #expect(StepStatus.skipped == StepStatus.skipped)
        #expect(StepStatus.failed(StepFailure(message: "a")) == StepStatus.failed(StepFailure(message: "a")))
        #expect(StepStatus.failed(StepFailure(message: "a")) != StepStatus.failed(StepFailure(message: "b")))
        #expect(StepStatus.passed != StepStatus.skipped)
    }

    // MARK: - ScenarioResult Status Derivation

    @Test("empty scenario has passed status")
    func emptyScenarioPassed() {
        let result = ScenarioResult(name: "empty", stepResults: [], tags: [])
        #expect(result.status == .passed)
    }

    @Test("all passed steps → scenario passed")
    func allStepsPassed() {
        let results = [
            StepResult(step: step("a"), status: .passed, duration: .milliseconds(10), location: nil),
            StepResult(step: step("b"), status: .passed, duration: .milliseconds(20), location: nil)
        ]
        let scenario = ScenarioResult(name: "test", stepResults: results, tags: [])
        #expect(scenario.status == .passed)
    }

    @Test("one failed step → scenario failed")
    func oneStepFailed() {
        let results = [
            StepResult(step: step("a"), status: .passed, duration: .zero, location: nil),
            StepResult(step: step("b"), status: .failed(StepFailure(message: "err")), duration: .zero, location: nil),
            StepResult(step: step("c"), status: .skipped, duration: .zero, location: nil)
        ]
        let scenario = ScenarioResult(name: "test", stepResults: results, tags: [])
        #expect(scenario.status == .failed(StepFailure(message: "err")))
    }

    @Test("undefined step → scenario undefined")
    func undefinedStep() {
        let results = [
            StepResult(step: step("a"), status: .passed, duration: .zero, location: nil),
            StepResult(step: step("b"), status: .undefined, duration: .zero, location: nil)
        ]
        let scenario = ScenarioResult(name: "test", stepResults: results, tags: [])
        #expect(scenario.status == .undefined)
    }

    @Test("ambiguous step → scenario ambiguous")
    func ambiguousStep() {
        let results = [
            StepResult(step: step("a"), status: .ambiguous, duration: .zero, location: nil)
        ]
        let scenario = ScenarioResult(name: "test", stepResults: results, tags: [])
        #expect(scenario.status == .ambiguous)
    }

    @Test("pending step → scenario pending")
    func pendingStep() {
        let results = [
            StepResult(step: step("a"), status: .pending, duration: .zero, location: nil)
        ]
        let scenario = ScenarioResult(name: "test", stepResults: results, tags: [])
        #expect(scenario.status == .pending)
    }

    @Test("all skipped → scenario skipped")
    func allSkipped() {
        let results = [
            StepResult(step: step("a"), status: .skipped, duration: .zero, location: nil),
            StepResult(step: step("b"), status: .skipped, duration: .zero, location: nil)
        ]
        let scenario = ScenarioResult(name: "test", stepResults: results, tags: [])
        #expect(scenario.status == .skipped)
    }

    @Test("failed overrides undefined in priority")
    func failedOverridesUndefined() {
        let results = [
            StepResult(step: step("a"), status: .undefined, duration: .zero, location: nil),
            StepResult(step: step("b"), status: .failed(StepFailure(message: "err")), duration: .zero, location: nil)
        ]
        let scenario = ScenarioResult(name: "test", stepResults: results, tags: [])
        #expect(scenario.status == .failed(StepFailure(message: "err")))
    }

    // MARK: - Duration Accumulation

    @Test("scenario duration sums step durations")
    func scenarioDuration() {
        let results = [
            StepResult(step: step("a"), status: .passed, duration: .milliseconds(10), location: nil),
            StepResult(step: step("b"), status: .passed, duration: .milliseconds(20), location: nil),
            StepResult(step: step("c"), status: .passed, duration: .milliseconds(30), location: nil)
        ]
        let scenario = ScenarioResult(name: "test", stepResults: results, tags: [])
        #expect(scenario.duration == .milliseconds(60))
    }

    @Test("feature duration sums scenario durations")
    func featureDuration() {
        let s1 = ScenarioResult(
            name: "s1",
            stepResults: [
                StepResult(step: step("a"), status: .passed, duration: .milliseconds(100), location: nil)
            ], tags: [])
        let s2 = ScenarioResult(
            name: "s2",
            stepResults: [
                StepResult(step: step("b"), status: .passed, duration: .milliseconds(200), location: nil)
            ], tags: [])
        let feature = FeatureResult(name: "feature", scenarioResults: [s1, s2], tags: [])
        #expect(feature.duration == .milliseconds(300))
    }

    // MARK: - FeatureResult Status Derivation

    @Test("feature with all passing scenarios → passed")
    func featureAllPassed() {
        let s1 = ScenarioResult(
            name: "s1",
            stepResults: [
                StepResult(step: step("a"), status: .passed, duration: .zero, location: nil)
            ], tags: [])
        let feature = FeatureResult(name: "f", scenarioResults: [s1], tags: [])
        #expect(feature.status == .passed)
    }

    @Test("feature with one failed scenario → failed")
    func featureOneFailed() {
        let s1 = ScenarioResult(
            name: "s1",
            stepResults: [
                StepResult(step: step("a"), status: .passed, duration: .zero, location: nil)
            ], tags: [])
        let s2 = ScenarioResult(
            name: "s2",
            stepResults: [
                StepResult(step: step("b"), status: .failed(StepFailure(message: "err")), duration: .zero, location: nil)
            ], tags: [])
        let feature = FeatureResult(name: "f", scenarioResults: [s1, s2], tags: [])
        #expect(feature.status == .failed(StepFailure(message: "err")))
    }

    @Test("empty feature → passed")
    func emptyFeature() {
        let feature = FeatureResult(name: "f", scenarioResults: [], tags: [])
        #expect(feature.status == .passed)
    }

    // MARK: - TestRunResult Summary Counts

    @Test("summary counts")
    func summaryCounts() {
        let passed = ScenarioResult(
            name: "p",
            stepResults: [
                StepResult(step: step("a"), status: .passed, duration: .zero, location: nil)
            ], tags: [])
        let failed = ScenarioResult(
            name: "f",
            stepResults: [
                StepResult(step: step("b"), status: .failed(StepFailure(message: "err")), duration: .zero, location: nil)
            ], tags: [])
        let undefined = ScenarioResult(
            name: "u",
            stepResults: [
                StepResult(step: step("c"), status: .undefined, duration: .zero, location: nil)
            ], tags: [])
        let pending = ScenarioResult(
            name: "pe",
            stepResults: [
                StepResult(step: step("d"), status: .pending, duration: .zero, location: nil)
            ], tags: [])
        let skipped = ScenarioResult(
            name: "s",
            stepResults: [
                StepResult(step: step("e"), status: .skipped, duration: .zero, location: nil)
            ], tags: [])

        let featureResult = FeatureResult(
            name: "test",
            scenarioResults: [passed, failed, undefined, pending, skipped],
            tags: []
        )
        let run = TestRunResult(featureResults: [featureResult], duration: .zero)

        #expect(run.totalCount == 5)
        #expect(run.passedCount == 1)
        #expect(run.failedCount == 1)
        #expect(run.undefinedCount == 1)
        #expect(run.pendingCount == 1)
        #expect(run.skippedCount == 1)
    }

    @Test("empty test run has zero counts")
    func emptyRunCounts() {
        let run = TestRunResult(featureResults: [], duration: .zero)
        #expect(run.totalCount == 0)
        #expect(run.passedCount == 0)
        #expect(run.failedCount == 0)
    }

    // MARK: - Equatable

    @Test("StepResult is equatable")
    func stepResultEquatable() {
        let a = StepResult(step: step("a"), status: .passed, duration: .milliseconds(10), location: Location(line: 1))
        let b = StepResult(step: step("a"), status: .passed, duration: .milliseconds(10), location: Location(line: 1))
        #expect(a == b)
    }

    @Test("ScenarioResult is equatable")
    func scenarioResultEquatable() {
        let a = ScenarioResult(name: "s", stepResults: [], tags: ["@smoke"])
        let b = ScenarioResult(name: "s", stepResults: [], tags: ["@smoke"])
        #expect(a == b)
    }

    @Test("FeatureResult is equatable")
    func featureResultEquatable() {
        let a = FeatureResult(name: "f", scenarioResults: [], tags: [])
        let b = FeatureResult(name: "f", scenarioResults: [], tags: [])
        #expect(a == b)
    }

    @Test("TestRunResult is equatable")
    func testRunResultEquatable() {
        let a = TestRunResult(featureResults: [], duration: .zero)
        let b = TestRunResult(featureResults: [], duration: .zero)
        #expect(a == b)
    }
}
