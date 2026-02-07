// AdvancedExecutionTests.swift
// GherkinTestingTests
//
// Copyright © 2026 Atelier Socle. MIT License.

import Testing

@testable import GherkinTesting

/// A minimal feature for advanced execution tests.
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
        handler: { _, _, _ in }
    )
}

/// Helper to build a pending step definition.
private func pendingDef(
    _ pattern: String,
    message: String = "Step implementation pending"
) -> StepDefinition<AdvFeature> {
    StepDefinition(
        pattern: .exact(pattern),
        sourceLocation: Location(line: 1),
        handler: { _, _, _ in throw PendingStepError(message) }
    )
}

/// Helper to build a failing step definition.
private func failDef(_ pattern: String) -> StepDefinition<AdvFeature> {
    struct AdvStepError: Error, CustomStringConvertible {
        let description: String
    }
    return StepDefinition(
        pattern: .exact(pattern),
        sourceLocation: Location(line: 1),
        handler: { _, _, _ in throw AdvStepError(description: "forced failure") }
    )
}

// MARK: - Pending Step Tests

@Suite("Pending Steps")
struct PendingStepTests {

    @Test("PendingStepError has default message")
    func defaultMessage() {
        let error = PendingStepError()
        #expect(error.message == "Step implementation pending")
        #expect(error.errorDescription == "Step implementation pending")
    }

    @Test("PendingStepError with custom message")
    func customMessage() {
        let error = PendingStepError("Not yet implemented")
        #expect(error.message == "Not yet implemented")
    }

    @Test("PendingStepError is Equatable")
    func equatable() {
        #expect(PendingStepError("a") == PendingStepError("a"))
        #expect(PendingStepError("a") != PendingStepError("b"))
    }

    @Test("pending step handler produces .pending status")
    func pendingStatus() async throws {
        let definitions = [
            noopDef("step A"),
            pendingDef("step B"),
            noopDef("step C")
        ]
        let pickle = advPickle(
            name: "Scenario",
            steps: [
                advStep("step A", id: "1"),
                advStep("step B", id: "2"),
                advStep("step C", id: "3")
            ])
        let runner = TestRunner(definitions: definitions)

        let result = try await runner.run(
            pickles: [pickle],
            featureName: "F",
            featureTags: [],
            feature: AdvFeature()
        )

        let stepResults = result.featureResults[0].scenarioResults[0].stepResults
        #expect(stepResults[0].status == .passed)
        #expect(stepResults[1].status == .pending)
        #expect(stepResults[2].status == .skipped)
    }

    @Test("pending scenario shows in pendingCount")
    func pendingCount() async throws {
        let definitions = [pendingDef("pending step")]
        let pickle = advPickle(name: "Scenario", steps: [advStep("pending step")])
        let runner = TestRunner(definitions: definitions)

        let result = try await runner.run(
            pickles: [pickle],
            featureName: "F",
            featureTags: [],
            feature: AdvFeature()
        )

        #expect(result.pendingCount == 1)
        #expect(result.passedCount == 0)
        #expect(result.failedCount == 0)
    }

    @Test("pending is distinct from failed")
    func pendingDistinctFromFailed() async throws {
        let definitions: [StepDefinition<AdvFeature>] = [
            pendingDef("pending"),
            failDef("failing")
        ]
        let p1 = advPickle(name: "S1", steps: [advStep("pending")], id: "p1")
        let p2 = advPickle(name: "S2", steps: [advStep("failing")], id: "p2")
        let runner = TestRunner(definitions: definitions)

        let result = try await runner.run(
            pickles: [p1, p2],
            featureName: "F",
            featureTags: [],
            feature: AdvFeature()
        )

        #expect(result.pendingCount == 1)
        #expect(result.failedCount == 1)
    }
}

// MARK: - Undefined Step Suggestion Tests

@Suite("Undefined Step Suggestions")
struct UndefinedSuggestionTests {

    @Test("undefined step in normal mode generates suggestion")
    func undefinedSuggestion() async throws {
        let runner = TestRunner<AdvFeature>(definitions: [])
        let pickle = advPickle(
            name: "S",
            steps: [
                advStep("the user has 42 items")
            ])

        let result = try await runner.run(
            pickles: [pickle],
            featureName: "F",
            featureTags: [],
            feature: AdvFeature()
        )

        let stepResult = result.featureResults[0].scenarioResults[0].stepResults[0]
        #expect(stepResult.status == .undefined)
        let suggestion = try #require(stepResult.suggestion)
        #expect(suggestion.stepText == "the user has 42 items")
        #expect(suggestion.suggestedExpression == "the user has {int} items")
    }

    @Test("defined step has no suggestion")
    func definedStepNoSuggestion() async throws {
        let definitions = [noopDef("step A")]
        let pickle = advPickle(name: "S", steps: [advStep("step A")])
        let runner = TestRunner(definitions: definitions)

        let result = try await runner.run(
            pickles: [pickle],
            featureName: "F",
            featureTags: [],
            feature: AdvFeature()
        )

        let stepResult = result.featureResults[0].scenarioResults[0].stepResults[0]
        #expect(stepResult.status == .passed)
        #expect(stepResult.suggestion == nil)
    }

    @Test("dry-run collects ALL undefined steps, not just first")
    func dryRunCollectsAll() async throws {
        let runner = TestRunner<AdvFeature>(
            definitions: [],
            configuration: GherkinConfiguration(dryRun: true)
        )
        let pickle = advPickle(
            name: "S",
            steps: [
                advStep("undefined step A", id: "1"),
                advStep("undefined step B", id: "2"),
                advStep("undefined step C", id: "3")
            ])

        let result = try await runner.run(
            pickles: [pickle],
            featureName: "F",
            featureTags: [],
            feature: AdvFeature()
        )

        let stepResults = result.featureResults[0].scenarioResults[0].stepResults
        #expect(stepResults.count == 3)
        #expect(stepResults[0].status == .undefined)
        #expect(stepResults[1].status == .undefined)
        #expect(stepResults[2].status == .undefined)
        #expect(stepResults[0].suggestion != nil)
        #expect(stepResults[1].suggestion != nil)
        #expect(stepResults[2].suggestion != nil)
    }

    @Test("dry-run allSuggestions collects from all scenarios")
    func dryRunAllSuggestions() async throws {
        let runner = TestRunner<AdvFeature>(
            definitions: [],
            configuration: GherkinConfiguration(dryRun: true)
        )
        let p1 = advPickle(name: "S1", steps: [advStep("undef1", id: "1")], id: "p1")
        let p2 = advPickle(name: "S2", steps: [advStep("undef2", id: "2")], id: "p2")

        let result = try await runner.run(
            pickles: [p1, p2],
            featureName: "F",
            featureTags: [],
            feature: AdvFeature()
        )

        #expect(result.allSuggestions.count == 2)
        #expect(result.allSuggestions[0].stepText == "undef1")
        #expect(result.allSuggestions[1].stepText == "undef2")
    }

    @Test("dry-run reports ambiguous steps without suggestions")
    func dryRunAmbiguousNoSuggestion() async throws {
        let definitions = [noopDef("ambig"), noopDef("ambig")]
        let runner = TestRunner(
            definitions: definitions,
            configuration: GherkinConfiguration(dryRun: true)
        )
        let pickle = advPickle(name: "S", steps: [advStep("ambig")])

        let result = try await runner.run(
            pickles: [pickle],
            featureName: "F",
            featureTags: [],
            feature: AdvFeature()
        )

        let stepResult = result.featureResults[0].scenarioResults[0].stepResults[0]
        #expect(stepResult.status == .ambiguous)
        #expect(stepResult.suggestion == nil)
    }

    @Test("dry-run does not execute handlers")
    func dryRunNoExecution() async throws {
        let log = AdvLog()
        let definitions: [StepDefinition<AdvFeature>] = [
            StepDefinition(
                pattern: .exact("step"),
                sourceLocation: Location(line: 1),
                handler: { _, _, _ in await log.append("executed") }
            )
        ]
        let pickle = advPickle(name: "S", steps: [advStep("step")])
        let runner = TestRunner(
            definitions: definitions,
            configuration: GherkinConfiguration(dryRun: true)
        )

        _ = try await runner.run(
            pickles: [pickle],
            featureName: "F",
            featureTags: [],
            feature: AdvFeature()
        )

        let entries = await log.entries
        #expect(entries.isEmpty)
    }

    @Test("allSuggestions is empty when no undefined steps")
    func allSuggestionsEmpty() async throws {
        let definitions = [noopDef("step")]
        let pickle = advPickle(name: "S", steps: [advStep("step")])
        let runner = TestRunner(definitions: definitions)

        let result = try await runner.run(
            pickles: [pickle],
            featureName: "F",
            featureTags: [],
            feature: AdvFeature()
        )

        #expect(result.allSuggestions.isEmpty)
    }
}

// MARK: - Ambiguous Step Detection Tests

@Suite("Ambiguous Step Detection")
struct AmbiguousDetectionTests {

    @Test("ambiguous error includes source locations")
    func ambiguousWithLocations() throws {
        let defs: [StepDefinition<AdvFeature>] = [
            StepDefinition(pattern: .exact("click"), sourceLocation: Location(line: 12), handler: { _, _, _ in }),
            StepDefinition(pattern: .exact("click"), sourceLocation: Location(line: 34), handler: { _, _, _ in })
        ]
        let matcher = RegexStepMatcher(definitions: defs)
        let step = PickleStep(id: "s1", text: "click", argument: nil, astNodeIds: [])

        #expect {
            try matcher.match(step)
        } throws: { error in
            guard let e = error as? StepMatchError,
                case .ambiguous(_, let descs) = e
            else { return false }
            return descs[0].contains("line 12") && descs[1].contains("line 34")
        }
    }

    @Test("ambiguous error message is well-formatted")
    func ambiguousMessageFormat() throws {
        let defs: [StepDefinition<AdvFeature>] = [
            StepDefinition(pattern: .exact("hello"), sourceLocation: Location(line: 10), handler: { _, _, _ in }),
            StepDefinition(pattern: .exact("hello"), sourceLocation: Location(line: 20), handler: { _, _, _ in })
        ]
        let matcher = RegexStepMatcher(definitions: defs)
        let step = PickleStep(id: "s1", text: "hello", argument: nil, astNodeIds: [])

        do {
            _ = try matcher.match(step)
            Issue.record("Expected ambiguous error")
        } catch let error as StepMatchError {
            let desc = error.errorDescription ?? ""
            #expect(desc.contains("Ambiguous step"))
            #expect(desc.contains("hello"))
            #expect(desc.contains("line 10"))
            #expect(desc.contains("line 20"))
        } catch {
            Issue.record("Unexpected error type: \(error)")
        }
    }
}

// MARK: - Tag Filtering Integrated Tests

@Suite("Tag Filtering Integrated")
struct TagFilteringIntegratedTests {

    @Test("tag-filtered scenarios appear as skipped, not silently dropped")
    func filteredScenariosSkipped() async throws {
        let definitions = [noopDef("step")]
        let smokePickle = advPickle(
            name: "Smoke",
            steps: [advStep("step")],
            tags: [advTag("@smoke")],
            id: "p1"
        )
        let wipPickle = advPickle(
            name: "WIP",
            steps: [advStep("step")],
            tags: [advTag("@wip")],
            id: "p2"
        )
        let config = GherkinConfiguration(tagFilter: try TagFilter("@smoke"))
        let runner = TestRunner(definitions: definitions, configuration: config)

        let result = try await runner.run(
            pickles: [smokePickle, wipPickle],
            featureName: "F",
            featureTags: [],
            feature: AdvFeature()
        )

        let scenarios = result.featureResults[0].scenarioResults
        #expect(scenarios.count == 2)
        #expect(scenarios[0].name == "Smoke")
        #expect(scenarios[0].status == .passed)
        #expect(scenarios[1].name == "WIP")
        #expect(scenarios[1].status == .skipped)
    }

    @Test("filtered scenario steps are all skipped")
    func filteredStepsAllSkipped() async throws {
        let definitions = [noopDef("step A"), noopDef("step B")]
        let pickle = advPickle(
            name: "Excluded",
            steps: [advStep("step A", id: "1"), advStep("step B", id: "2")],
            tags: [advTag("@wip")]
        )
        let config = GherkinConfiguration(tagFilter: try TagFilter("@smoke"))
        let runner = TestRunner(definitions: definitions, configuration: config)

        let result = try await runner.run(
            pickles: [pickle],
            featureName: "F",
            featureTags: [],
            feature: AdvFeature()
        )

        let steps = result.featureResults[0].scenarioResults[0].stepResults
        #expect(steps.count == 2)
        #expect(steps[0].status == .skipped)
        #expect(steps[1].status == .skipped)
    }

    @Test("tag filter with complex boolean expression")
    func complexTagFilter() async throws {
        let definitions = [noopDef("step")]
        let p1 = advPickle(
            name: "S1", steps: [advStep("step")],
            tags: [advTag("@smoke"), advTag("@login")], id: "p1")
        let p2 = advPickle(
            name: "S2", steps: [advStep("step")],
            tags: [advTag("@smoke"), advTag("@wip")], id: "p2")
        let p3 = advPickle(
            name: "S3", steps: [advStep("step")],
            tags: [advTag("@login")], id: "p3")
        let config = GherkinConfiguration(tagFilter: try TagFilter("@smoke and not @wip"))
        let runner = TestRunner(definitions: definitions, configuration: config)

        let result = try await runner.run(
            pickles: [p1, p2, p3],
            featureName: "F",
            featureTags: [],
            feature: AdvFeature()
        )

        let scenarios = result.featureResults[0].scenarioResults
        #expect(scenarios.count == 3)
        #expect(scenarios[0].status == .passed)  // @smoke @login → matches
        #expect(scenarios[1].status == .skipped)  // @smoke @wip → filtered
        #expect(scenarios[2].status == .skipped)  // @login → no @smoke
    }

    @Test("skipped count includes tag-filtered scenarios")
    func skippedCountIncludesFiltered() async throws {
        let definitions = [noopDef("step")]
        let p1 = advPickle(
            name: "S1", steps: [advStep("step")],
            tags: [advTag("@smoke")], id: "p1")
        let p2 = advPickle(
            name: "S2", steps: [advStep("step")],
            tags: [advTag("@wip")], id: "p2")
        let config = GherkinConfiguration(tagFilter: try TagFilter("@smoke"))
        let runner = TestRunner(definitions: definitions, configuration: config)

        let result = try await runner.run(
            pickles: [p1, p2],
            featureName: "F",
            featureTags: [],
            feature: AdvFeature()
        )

        #expect(result.passedCount == 1)
        #expect(result.skippedCount == 1)
        #expect(result.totalCount == 2)
    }
}
