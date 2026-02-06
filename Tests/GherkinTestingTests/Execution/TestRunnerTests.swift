// TestRunnerTests.swift
// GherkinTestingTests
//
// Copyright © 2026 Atelier Socle. MIT License.

import Testing

@testable import GherkinTesting

/// A minimal feature for runner tests.
private struct RunnerTestFeature: GherkinFeature {
    var log: [String] = []
}

/// Thread-safe log for hook/step execution tracking in runner tests.
private actor RunnerLog {
    var entries: [String] = []

    func append(_ entry: String) {
        entries.append(entry)
    }
}

/// Helper to build a Pickle.
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

/// Helper to build a PickleStep.
private func makeStep(_ text: String, id: String = "step") -> PickleStep {
    PickleStep(id: id, text: text, argument: nil, astNodeIds: [])
}

/// Helper to build a PickleTag.
private func makeTag(_ name: String) -> PickleTag {
    PickleTag(name: name, astNodeId: "1:1")
}

/// Helper to build an exact step definition that logs execution.
private func loggingDefinition(
    _ pattern: String,
    log: RunnerLog
) -> StepDefinition<RunnerTestFeature> {
    StepDefinition(
        pattern: .exact(pattern),
        sourceLocation: Location(line: 1),
        handler: { _, _ in await log.append("exec:\(pattern)") }
    )
}

/// Helper to build a no-op exact step definition.
private func noopDefinition(_ pattern: String) -> StepDefinition<RunnerTestFeature> {
    StepDefinition(
        pattern: .exact(pattern),
        sourceLocation: Location(line: 1),
        handler: { _, _ in }
    )
}

/// Helper to build a failing step definition.
private func failingDefinition(_ pattern: String) -> StepDefinition<RunnerTestFeature> {
    struct StepError: Error, CustomStringConvertible {
        let description: String
    }
    return StepDefinition(
        pattern: .exact(pattern),
        sourceLocation: Location(line: 1),
        handler: { _, _ in throw StepError(description: "forced failure") }
    )
}

@Suite("TestRunner")
struct TestRunnerTests {

    // MARK: - Complete Execution

    @Test("executes all steps in a single pickle")
    func executeAllSteps() async throws {
        let log = RunnerLog()
        let definitions = [
            loggingDefinition("step A", log: log),
            loggingDefinition("step B", log: log),
            loggingDefinition("step C", log: log)
        ]
        let pickle = makePickle(
            name: "Scenario 1",
            steps: [
                makeStep("step A", id: "1"),
                makeStep("step B", id: "2"),
                makeStep("step C", id: "3")
            ])
        let runner = TestRunner(definitions: definitions)

        let result = try await runner.run(
            pickles: [pickle],
            featureName: "Test Feature",
            featureTags: [],
            feature: RunnerTestFeature()
        )

        let entries = await log.entries
        #expect(entries == ["exec:step A", "exec:step B", "exec:step C"])
        #expect(result.passedCount == 1)
        #expect(result.failedCount == 0)
        #expect(result.featureResults.count == 1)
        #expect(result.featureResults[0].scenarioResults.count == 1)
        #expect(result.featureResults[0].scenarioResults[0].status == .passed)
    }

    @Test("executes multiple pickles")
    func multiplePickles() async throws {
        let definitions = [noopDefinition("step")]
        let pickles = [
            makePickle(name: "S1", steps: [makeStep("step")], id: "p1"),
            makePickle(name: "S2", steps: [makeStep("step")], id: "p2"),
            makePickle(name: "S3", steps: [makeStep("step")], id: "p3")
        ]
        let runner = TestRunner(definitions: definitions)

        let result = try await runner.run(
            pickles: pickles,
            featureName: "Multi",
            featureTags: [],
            feature: RunnerTestFeature()
        )

        #expect(result.featureResults[0].scenarioResults.count == 3)
        #expect(result.passedCount == 3)
    }

    // MARK: - Skip After Failure

    @Test("steps after failure are skipped")
    func skipAfterFailure() async throws {
        let definitions: [StepDefinition<RunnerTestFeature>] = [
            noopDefinition("step A"),
            failingDefinition("step B"),
            noopDefinition("step C")
        ]
        let pickle = makePickle(
            name: "Scenario",
            steps: [
                makeStep("step A", id: "1"),
                makeStep("step B", id: "2"),
                makeStep("step C", id: "3")
            ])
        let runner = TestRunner(definitions: definitions)

        let result = try await runner.run(
            pickles: [pickle],
            featureName: "F",
            featureTags: [],
            feature: RunnerTestFeature()
        )

        let stepResults = result.featureResults[0].scenarioResults[0].stepResults
        #expect(stepResults[0].status == .passed)
        if case .failed = stepResults[1].status {
            // expected
        } else {
            Issue.record("Expected step B to be failed")
        }
        #expect(stepResults[2].status == .skipped)
    }

    @Test("undefined step causes remaining steps to be skipped")
    func undefinedSkipsRest() async throws {
        let definitions = [noopDefinition("step A")]
        let pickle = makePickle(
            name: "Scenario",
            steps: [
                makeStep("step A", id: "1"),
                makeStep("undefined step", id: "2"),
                makeStep("step A", id: "3")
            ])
        let runner = TestRunner(definitions: definitions)

        let result = try await runner.run(
            pickles: [pickle],
            featureName: "F",
            featureTags: [],
            feature: RunnerTestFeature()
        )

        let stepResults = result.featureResults[0].scenarioResults[0].stepResults
        #expect(stepResults[0].status == .passed)
        #expect(stepResults[1].status == .undefined)
        #expect(stepResults[2].status == .skipped)
    }

    // MARK: - Dry Run Mode

    @Test("dry-run mode matches but does not execute")
    func dryRunMode() async throws {
        let log = RunnerLog()
        let definitions = [loggingDefinition("step A", log: log)]
        let pickle = makePickle(
            name: "Scenario",
            steps: [
                makeStep("step A")
            ])
        let config = GherkinConfiguration(dryRun: true)
        let runner = TestRunner(definitions: definitions, configuration: config)

        let result = try await runner.run(
            pickles: [pickle],
            featureName: "F",
            featureTags: [],
            feature: RunnerTestFeature()
        )

        let entries = await log.entries
        #expect(entries.isEmpty)
        #expect(result.featureResults[0].scenarioResults[0].stepResults[0].status == .passed)
    }

    @Test("dry-run reports undefined steps")
    func dryRunReportsUndefined() async throws {
        let runner = TestRunner<RunnerTestFeature>(
            definitions: [],
            configuration: GherkinConfiguration(dryRun: true)
        )
        let pickle = makePickle(
            name: "Scenario",
            steps: [
                makeStep("missing step")
            ])

        let result = try await runner.run(
            pickles: [pickle],
            featureName: "F",
            featureTags: [],
            feature: RunnerTestFeature()
        )

        #expect(result.featureResults[0].scenarioResults[0].stepResults[0].status == .undefined)
    }

    @Test("dry-run reports ambiguous steps")
    func dryRunReportsAmbiguous() async throws {
        let definitions = [
            noopDefinition("ambiguous step"),
            noopDefinition("ambiguous step")
        ]
        let runner = TestRunner(
            definitions: definitions,
            configuration: GherkinConfiguration(dryRun: true)
        )
        let pickle = makePickle(
            name: "Scenario",
            steps: [
                makeStep("ambiguous step")
            ])

        let result = try await runner.run(
            pickles: [pickle],
            featureName: "F",
            featureTags: [],
            feature: RunnerTestFeature()
        )

        #expect(result.featureResults[0].scenarioResults[0].stepResults[0].status == .ambiguous)
    }

}

// MARK: - Tag Filtering

extension TestRunnerTests {

    @Test("tag filter marks non-matching pickles as skipped")
    func tagFilterSkips() async throws {
        let definitions = [noopDefinition("step")]
        let smokePickle = makePickle(
            name: "Smoke",
            steps: [makeStep("step")],
            tags: [makeTag("@smoke")],
            id: "p1"
        )
        let wipPickle = makePickle(
            name: "WIP",
            steps: [makeStep("step")],
            tags: [makeTag("@wip")],
            id: "p2"
        )
        let config = GherkinConfiguration(tagFilter: try TagFilter("@smoke"))
        let runner = TestRunner(definitions: definitions, configuration: config)

        let result = try await runner.run(
            pickles: [smokePickle, wipPickle],
            featureName: "F",
            featureTags: [],
            feature: RunnerTestFeature()
        )

        #expect(result.featureResults[0].scenarioResults.count == 2)
        #expect(result.featureResults[0].scenarioResults[0].name == "Smoke")
        #expect(result.featureResults[0].scenarioResults[0].status == .passed)
        #expect(result.featureResults[0].scenarioResults[1].name == "WIP")
        #expect(result.featureResults[0].scenarioResults[1].status == .skipped)
    }

    @Test("tag filter with not expression")
    func tagFilterNotExpression() async throws {
        let definitions = [noopDefinition("step")]
        let normalPickle = makePickle(
            name: "Normal",
            steps: [makeStep("step")],
            tags: [makeTag("@smoke")],
            id: "p1"
        )
        let wipPickle = makePickle(
            name: "WIP",
            steps: [makeStep("step")],
            tags: [makeTag("@wip")],
            id: "p2"
        )
        let config = GherkinConfiguration(tagFilter: try TagFilter("not @wip"))
        let runner = TestRunner(definitions: definitions, configuration: config)

        let result = try await runner.run(
            pickles: [normalPickle, wipPickle],
            featureName: "F",
            featureTags: [],
            feature: RunnerTestFeature()
        )

        #expect(result.featureResults[0].scenarioResults.count == 2)
        #expect(result.featureResults[0].scenarioResults[0].name == "Normal")
        #expect(result.featureResults[0].scenarioResults[0].status == .passed)
        #expect(result.featureResults[0].scenarioResults[1].name == "WIP")
        #expect(result.featureResults[0].scenarioResults[1].status == .skipped)
    }
}

// MARK: - Hooks Lifecycle

extension TestRunnerTests {

    @Test("hooks execute in correct lifecycle order")
    func hooksLifecycle() async throws {
        let log = RunnerLog()
        let definitions: [StepDefinition<RunnerTestFeature>] = [
            StepDefinition(
                pattern: .exact("do something"),
                sourceLocation: Location(line: 1),
                handler: { _, _ in await log.append("step-exec") }
            )
        ]
        var hooks = HookRegistry()
        hooks.addBefore(Hook(scope: .feature) { await log.append("before-feature") })
        hooks.addBefore(Hook(scope: .scenario) { await log.append("before-scenario") })
        hooks.addBefore(Hook(scope: .step) { await log.append("before-step") })
        hooks.addAfter(Hook(scope: .step) { await log.append("after-step") })
        hooks.addAfter(Hook(scope: .scenario) { await log.append("after-scenario") })
        hooks.addAfter(Hook(scope: .feature) { await log.append("after-feature") })

        let pickle = makePickle(name: "S", steps: [makeStep("do something")])
        let runner = TestRunner(definitions: definitions, hooks: hooks)

        _ = try await runner.run(
            pickles: [pickle],
            featureName: "F",
            featureTags: [],
            feature: RunnerTestFeature()
        )

        let entries = await log.entries
        #expect(
            entries == [
                "before-feature",
                "before-scenario",
                "before-step",
                "step-exec",
                "after-step",
                "after-scenario",
                "after-feature"
            ])
    }

    @Test("after hooks run even when step fails")
    func afterHooksRunOnFailure() async throws {
        let log = RunnerLog()
        var hooks = HookRegistry()
        hooks.addAfter(Hook(scope: .scenario) { await log.append("after-scenario") })
        hooks.addAfter(Hook(scope: .step) { await log.append("after-step") })

        let definitions = [failingDefinition("fail step")]
        let pickle = makePickle(name: "S", steps: [makeStep("fail step")])
        let runner = TestRunner(definitions: definitions, hooks: hooks)

        _ = try await runner.run(
            pickles: [pickle],
            featureName: "F",
            featureTags: [],
            feature: RunnerTestFeature()
        )

        let entries = await log.entries
        #expect(entries.contains("after-step"))
        #expect(entries.contains("after-scenario"))
    }
}

// MARK: - Edge Cases

extension TestRunnerTests {

    @Test("empty pickle list produces empty results")
    func emptyPickles() async throws {
        let runner = TestRunner<RunnerTestFeature>(definitions: [])

        let result = try await runner.run(
            pickles: [],
            featureName: "Empty",
            featureTags: [],
            feature: RunnerTestFeature()
        )

        #expect(result.featureResults[0].scenarioResults.isEmpty)
        #expect(result.totalCount == 0)
    }

    @Test("pickle with zero steps produces passed scenario")
    func zeroStepPickle() async throws {
        let runner = TestRunner<RunnerTestFeature>(definitions: [])
        let pickle = makePickle(name: "Empty Scenario", steps: [])

        let result = try await runner.run(
            pickles: [pickle],
            featureName: "F",
            featureTags: [],
            feature: RunnerTestFeature()
        )

        #expect(result.passedCount == 1)
        #expect(result.featureResults[0].scenarioResults[0].status == .passed)
    }

    @Test("all undefined steps")
    func allUndefined() async throws {
        let runner = TestRunner<RunnerTestFeature>(definitions: [])
        let pickle = makePickle(
            name: "S",
            steps: [
                makeStep("undef1", id: "1"),
                makeStep("undef2", id: "2")
            ])

        let result = try await runner.run(
            pickles: [pickle],
            featureName: "F",
            featureTags: [],
            feature: RunnerTestFeature()
        )

        let stepResults = result.featureResults[0].scenarioResults[0].stepResults
        #expect(stepResults[0].status == .undefined)
        #expect(stepResults[1].status == .skipped)
    }

    @Test("scenario isolation: each pickle gets fresh feature copy")
    func scenarioIsolation() async throws {
        let definitions: [StepDefinition<RunnerTestFeature>] = [
            StepDefinition(
                pattern: .exact("mutate"),
                sourceLocation: Location(line: 1),
                handler: { feature, _ in
                    feature.log.append("mutated")
                }
            )
        ]
        let pickle1 = makePickle(name: "S1", steps: [makeStep("mutate")], id: "p1")
        let pickle2 = makePickle(name: "S2", steps: [makeStep("mutate")], id: "p2")
        let runner = TestRunner(definitions: definitions)

        let result = try await runner.run(
            pickles: [pickle1, pickle2],
            featureName: "F",
            featureTags: [],
            feature: RunnerTestFeature()
        )

        #expect(result.passedCount == 2)
    }

    @Test("result includes feature name and tags")
    func resultMetadata() async throws {
        let runner = TestRunner<RunnerTestFeature>(definitions: [])

        let result = try await runner.run(
            pickles: [],
            featureName: "My Feature",
            featureTags: ["@smoke", "@login"],
            feature: RunnerTestFeature()
        )

        #expect(result.featureResults[0].name == "My Feature")
        #expect(result.featureResults[0].tags == ["@smoke", "@login"])
    }

    @Test("result has non-negative duration")
    func resultDuration() async throws {
        let definitions = [noopDefinition("step")]
        let pickle = makePickle(name: "S", steps: [makeStep("step")])
        let runner = TestRunner(definitions: definitions)

        let result = try await runner.run(
            pickles: [pickle],
            featureName: "F",
            featureTags: [],
            feature: RunnerTestFeature()
        )

        #expect(result.duration >= .zero)
    }
}
