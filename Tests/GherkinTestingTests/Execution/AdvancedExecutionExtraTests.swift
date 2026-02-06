// AdvancedExecutionExtraTests.swift
// GherkinTestingTests
//
// Copyright © 2026 Atelier Socle. MIT License.

import Testing

@testable import GherkinTesting

/// A minimal feature for advanced execution extra tests.
private struct AdvFeature: GherkinFeature {
    var log: [String] = []
}

/// Thread-safe log for hook/step execution tracking.
private actor AdvLog {
    var entries: [String] = []

    func append(_ entry: String) {
        entries.append(entry)
    }
}

/// Helper to build a Pickle.
private func advPickle(
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
private func advStep(_ text: String, id: String = "step") -> PickleStep {
    PickleStep(id: id, text: text, argument: nil, astNodeIds: [])
}

/// Helper to build a PickleTag.
private func advTag(_ name: String) -> PickleTag {
    PickleTag(name: name, astNodeId: "1:1")
}

/// Helper to build a no-op exact step definition.
private func noopDef(_ pattern: String) -> StepDefinition<AdvFeature> {
    StepDefinition(
        pattern: .exact(pattern),
        sourceLocation: Location(line: 1),
        handler: { _, _ in }
    )
}

// MARK: - Hook Ordering Tests

@Suite("Hook Ordering")
struct HookOrderingTests {

    @Test("before hooks execute in ascending order")
    func beforeHooksAscending() async throws {
        let log = AdvLog()
        var registry = HookRegistry()
        registry.addBefore(Hook(scope: .scenario, order: 20) { await log.append("order-20") })
        registry.addBefore(Hook(scope: .scenario, order: 10) { await log.append("order-10") })
        registry.addBefore(Hook(scope: .scenario, order: 30) { await log.append("order-30") })

        try await registry.executeBefore(scope: .scenario, tags: [])
        let entries = await log.entries
        #expect(entries == ["order-10", "order-20", "order-30"])
    }

    @Test("after hooks execute in descending order")
    func afterHooksDescending() async throws {
        let log = AdvLog()
        var registry = HookRegistry()
        registry.addAfter(Hook(scope: .scenario, order: 20) { await log.append("order-20") })
        registry.addAfter(Hook(scope: .scenario, order: 10) { await log.append("order-10") })
        registry.addAfter(Hook(scope: .scenario, order: 30) { await log.append("order-30") })

        try await registry.executeAfter(scope: .scenario, tags: [])
        let entries = await log.entries
        #expect(entries == ["order-30", "order-20", "order-10"])
    }

    @Test("same order preserves FIFO for before hooks")
    func sameOrderFIFO() async throws {
        let log = AdvLog()
        var registry = HookRegistry()
        registry.addBefore(Hook(scope: .scenario, order: 0) { await log.append("first") })
        registry.addBefore(Hook(scope: .scenario, order: 0) { await log.append("second") })
        registry.addBefore(Hook(scope: .scenario, order: 0) { await log.append("third") })

        try await registry.executeBefore(scope: .scenario, tags: [])
        let entries = await log.entries
        #expect(entries == ["first", "second", "third"])
    }

    @Test("same order preserves LIFO for after hooks")
    func sameOrderLIFO() async throws {
        let log = AdvLog()
        var registry = HookRegistry()
        registry.addAfter(Hook(scope: .scenario, order: 0) { await log.append("first") })
        registry.addAfter(Hook(scope: .scenario, order: 0) { await log.append("second") })
        registry.addAfter(Hook(scope: .scenario, order: 0) { await log.append("third") })

        try await registry.executeAfter(scope: .scenario, tags: [])
        let entries = await log.entries
        #expect(entries == ["third", "second", "first"])
    }

    @Test("mixed orders with same and different values")
    func mixedOrders() async throws {
        let log = AdvLog()
        var registry = HookRegistry()
        registry.addBefore(Hook(scope: .scenario, order: 1) { await log.append("B-order1") })
        registry.addBefore(Hook(scope: .scenario, order: 0) { await log.append("A-order0") })
        registry.addBefore(Hook(scope: .scenario, order: 1) { await log.append("C-order1") })
        registry.addBefore(Hook(scope: .scenario, order: 0) { await log.append("D-order0") })

        try await registry.executeBefore(scope: .scenario, tags: [])
        let entries = await log.entries
        #expect(entries == ["A-order0", "D-order0", "B-order1", "C-order1"])
    }

    @Test("default order is 0")
    func defaultOrderIsZero() {
        let hook = Hook(scope: .scenario) {}
        #expect(hook.order == 0)
    }

    @Test("hook with tag filter and order")
    func hookWithTagFilterAndOrder() async throws {
        let log = AdvLog()
        var registry = HookRegistry()
        registry.addBefore(
            Hook(
                scope: .scenario,
                order: 10,
                tagFilter: try TagFilter("@smoke"),
                handler: { await log.append("smoke-10") }
            ))
        registry.addBefore(
            Hook(
                scope: .scenario,
                order: 5,
                handler: { await log.append("always-5") }
            ))

        try await registry.executeBefore(scope: .scenario, tags: ["@smoke"])
        let entries = await log.entries
        #expect(entries == ["always-5", "smoke-10"])
    }

    @Test("hook with tag filter skipped when tags don't match, regardless of order")
    func hookFilteredOutByTag() async throws {
        let log = AdvLog()
        var registry = HookRegistry()
        registry.addBefore(
            Hook(
                scope: .scenario,
                order: 1,
                tagFilter: try TagFilter("@smoke"),
                handler: { await log.append("smoke") }
            ))
        registry.addBefore(
            Hook(
                scope: .scenario,
                order: 2,
                handler: { await log.append("always") }
            ))

        try await registry.executeBefore(scope: .scenario, tags: ["@login"])
        let entries = await log.entries
        #expect(entries == ["always"])
    }
}

// MARK: - Dry-Run Enhanced Tests

@Suite("Dry-Run Enhanced")
struct DryRunEnhancedTests {

    @Test("dry-run matches all steps including after undefined")
    func dryRunMatchesAllSteps() async throws {
        let definitions = [noopDef("step A")]
        let runner = TestRunner(
            definitions: definitions,
            configuration: GherkinConfiguration(dryRun: true)
        )
        let pickle = advPickle(
            name: "S",
            steps: [
                advStep("step A", id: "1"),
                advStep("undefined B", id: "2"),
                advStep("step A", id: "3")
            ])

        let result = try await runner.run(
            pickles: [pickle],
            featureName: "F",
            featureTags: [],
            feature: AdvFeature()
        )

        let stepResults = result.featureResults[0].scenarioResults[0].stepResults
        #expect(stepResults[0].status == .passed)
        #expect(stepResults[1].status == .undefined)
        #expect(stepResults[2].status == .passed)
    }

    @Test("dry-run collects suggestions for undefined only")
    func dryRunSuggestionsUndefinedOnly() async throws {
        let definitions = [noopDef("defined")]
        let runner = TestRunner(
            definitions: definitions,
            configuration: GherkinConfiguration(dryRun: true)
        )
        let pickle = advPickle(
            name: "S",
            steps: [
                advStep("defined", id: "1"),
                advStep("the user has 42 items", id: "2")
            ])

        let result = try await runner.run(
            pickles: [pickle],
            featureName: "F",
            featureTags: [],
            feature: AdvFeature()
        )

        #expect(result.allSuggestions.count == 1)
        #expect(result.allSuggestions[0].suggestedExpression == "the user has {int} items")
    }

    @Test("dry-run reports ambiguous without crashing")
    func dryRunReportsAmbiguous() async throws {
        let definitions = [noopDef("step"), noopDef("step")]
        let runner = TestRunner(
            definitions: definitions,
            configuration: GherkinConfiguration(dryRun: true)
        )
        let pickle = advPickle(
            name: "S",
            steps: [
                advStep("step", id: "1"),
                advStep("other step", id: "2")
            ])

        let result = try await runner.run(
            pickles: [pickle],
            featureName: "F",
            featureTags: [],
            feature: AdvFeature()
        )

        let stepResults = result.featureResults[0].scenarioResults[0].stepResults
        #expect(stepResults[0].status == .ambiguous)
        #expect(stepResults[1].status == .undefined)
    }

    @Test("dry-run across multiple pickles collects all suggestions")
    func dryRunMultiplePickles() async throws {
        let runner = TestRunner<AdvFeature>(
            definitions: [],
            configuration: GherkinConfiguration(dryRun: true)
        )
        let p1 = advPickle(
            name: "S1",
            steps: [
                advStep("user enters \"Alice\"", id: "1")
            ], id: "p1")
        let p2 = advPickle(
            name: "S2",
            steps: [
                advStep("user has 3.14 balance", id: "2")
            ], id: "p2")

        let result = try await runner.run(
            pickles: [p1, p2],
            featureName: "F",
            featureTags: [],
            feature: AdvFeature()
        )

        #expect(result.allSuggestions.count == 2)
        #expect(result.allSuggestions[0].suggestedExpression == "user enters {string}")
        #expect(result.allSuggestions[1].suggestedExpression == "user has {float} balance")
    }
}

// MARK: - FeatureExecutionError Tests

@Suite("FeatureExecutionError")
struct FeatureExecutionErrorTests {

    @Test("errorDescription joins multiple failures")
    func errorDescription() {
        let error = FeatureExecutionError(failures: ["Step failed: X", "Step undefined: Y"])
        let desc = error.errorDescription ?? ""
        #expect(desc.contains("Step failed: X"))
        #expect(desc.contains("Step undefined: Y"))
        #expect(desc.contains("Feature execution failed:"))
    }

    @Test("empty failures still produces valid description")
    func emptyFailures() {
        let error = FeatureExecutionError(failures: [])
        let desc = error.errorDescription
        #expect(desc == "Feature execution failed:\n")
    }

    @Test("single failure description")
    func singleFailure() {
        let error = FeatureExecutionError(failures: ["assertion failed"])
        let desc = error.errorDescription ?? ""
        #expect(desc.contains("  - assertion failed"))
    }
}

// MARK: - ReporterError Tests

@Suite("ReporterError")
struct ReporterErrorTests {

    @Test("encodingFailed is an Error")
    func isError() {
        let error: any Error = ReporterError.encodingFailed
        #expect(error is ReporterError)
    }

    @Test("encodingFailed is Sendable")
    func isSendable() {
        let error: any Sendable = ReporterError.encodingFailed
        #expect(error is ReporterError)
    }
}
