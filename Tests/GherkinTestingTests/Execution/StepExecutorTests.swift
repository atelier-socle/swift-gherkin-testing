// StepExecutorTests.swift
// GherkinTestingTests
//
// Copyright © 2026 Atelier Socle. MIT License.

import Testing

@testable import GherkinTesting

/// A minimal feature type for testing step execution.
struct TestFeature: GherkinFeature {
    var executedSteps: [String] = []
    var capturedArgs: [[String]] = []
}

/// Helper to create a PickleStep with the given text.
private func pickleStep(_ text: String) -> PickleStep {
    PickleStep(id: "step-1", text: text, argument: nil, astNodeIds: [])
}

/// Helper to create a StepDefinition with an exact pattern.
private func exactDefinition(
    _ pattern: String,
    keywordType: StepKeywordType? = nil,
    line: Int = 1,
    handler: @escaping @Sendable (inout TestFeature, [String], StepArgument?) async throws -> Void = { _, _, _ in }
) -> StepDefinition<TestFeature> {
    StepDefinition(
        keywordType: keywordType,
        pattern: .exact(pattern),
        sourceLocation: Location(line: line),
        handler: handler
    )
}

/// Helper to create a StepDefinition with a regex pattern.
private func regexDefinition(
    _ pattern: String,
    keywordType: StepKeywordType? = nil,
    line: Int = 1,
    handler: @escaping @Sendable (inout TestFeature, [String], StepArgument?) async throws -> Void = { _, _, _ in }
) -> StepDefinition<TestFeature> {
    StepDefinition(
        keywordType: keywordType,
        pattern: .regex(pattern),
        sourceLocation: Location(line: line),
        handler: handler
    )
}

@Suite("StepExecutor")
struct StepExecutorTests {

    // MARK: - Exact Match

    @Test("matches step with exact string pattern")
    func exactMatch() throws {
        let definition = exactDefinition("the user is logged in")
        let executor = StepExecutor(definitions: [definition])
        let step = pickleStep("the user is logged in")

        let match = try executor.match(step)
        #expect(match.arguments.isEmpty)
        #expect(match.matchLocation == Location(line: 1))
    }

    @Test("exact match is case-sensitive")
    func exactMatchCaseSensitive() throws {
        let definition = exactDefinition("the user is logged in")
        let executor = StepExecutor(definitions: [definition])
        let step = pickleStep("The User Is Logged In")

        #expect(throws: StepMatchError.self) {
            try executor.match(step)
        }
    }

    @Test("exact match requires full text equality")
    func exactMatchFullEquality() throws {
        let definition = exactDefinition("the user is logged in")
        let executor = StepExecutor(definitions: [definition])

        let step = pickleStep("the user is logged in now")
        #expect(throws: StepMatchError.self) {
            try executor.match(step)
        }
    }

    // MARK: - Regex Match

    @Test("matches step with regex pattern")
    func regexMatch() throws {
        let definition = regexDefinition("^the user is on the (.+) page$")
        let executor = StepExecutor(definitions: [definition])
        let step = pickleStep("the user is on the login page")

        let match = try executor.match(step)
        #expect(match.arguments == ["login"])
    }

    @Test("extracts multiple capture groups")
    func regexMultipleCaptures() throws {
        let definition = regexDefinition("^(.+) enters (.+) and (.+)$")
        let executor = StepExecutor(definitions: [definition])
        let step = pickleStep("Alice enters password123 and submit")

        let match = try executor.match(step)
        #expect(match.arguments == ["Alice", "password123", "submit"])
    }

    @Test("regex with no capture groups returns empty arguments")
    func regexNoCaptureGroups() throws {
        let definition = regexDefinition("^the user clicks submit$")
        let executor = StepExecutor(definitions: [definition])
        let step = pickleStep("the user clicks submit")

        let match = try executor.match(step)
        #expect(match.arguments.isEmpty)
    }

    @Test("regex uses wholeMatch, not partial match")
    func regexWholeMatch() throws {
        let definition = regexDefinition("^hello$")
        let executor = StepExecutor(definitions: [definition])
        let step = pickleStep("hello world")

        #expect(throws: StepMatchError.self) {
            try executor.match(step)
        }
    }

    @Test("extracts numeric capture groups as strings")
    func regexNumericCapture() throws {
        let definition = regexDefinition("^the user has (\\d+) items in the cart$")
        let executor = StepExecutor(definitions: [definition])
        let step = pickleStep("the user has 42 items in the cart")

        let match = try executor.match(step)
        #expect(match.arguments == ["42"])
    }

    // MARK: - Undefined Step

    @Test("throws undefined error when no definitions exist")
    func undefinedNoDefinitions() throws {
        let executor = StepExecutor<TestFeature>(definitions: [])
        let step = pickleStep("some step")

        #expect {
            try executor.match(step)
        } throws: { error in
            guard let matchError = error as? StepMatchError else { return false }
            return matchError == .undefined(stepText: "some step")
        }
    }

    @Test("throws undefined when no definition matches")
    func undefinedNoMatch() throws {
        let definition = exactDefinition("the user is logged in")
        let executor = StepExecutor(definitions: [definition])
        let step = pickleStep("the user is logged out")

        #expect {
            try executor.match(step)
        } throws: { error in
            guard let matchError = error as? StepMatchError else { return false }
            return matchError == .undefined(stepText: "the user is logged out")
        }
    }

    // MARK: - Ambiguous Step

    @Test("throws ambiguous error when multiple definitions match")
    func ambiguousMatch() throws {
        let def1 = exactDefinition("the user clicks", line: 1)
        let def2 = exactDefinition("the user clicks", line: 2)
        let executor = StepExecutor(definitions: [def1, def2])
        let step = pickleStep("the user clicks")

        #expect {
            try executor.match(step)
        } throws: { error in
            guard let matchError = error as? StepMatchError else { return false }
            if case .ambiguous(let text, let descs) = matchError {
                return text == "the user clicks" && descs.count == 2
            }
            return false
        }
    }

    @Test("exact match takes priority over regex match")
    func exactPriorityOverRegex() throws {
        let def1 = exactDefinition("the user clicks submit", line: 1)
        let def2 = regexDefinition("^the user clicks (.+)$", line: 2)
        let executor = StepExecutor(definitions: [def1, def2])
        let step = pickleStep("the user clicks submit")

        let match = try executor.match(step)
        #expect(match.matchLocation == Location(line: 1))
        #expect(match.arguments.isEmpty)
    }

    // MARK: - Execution

    @Test("execute calls handler with matched arguments")
    func executeCallsHandler() async throws {
        let definition = regexDefinition("^the user enters (.+)$") { feature, args, _ in
            feature.executedSteps.append("enter")
            feature.capturedArgs.append(args)
        }
        let executor = StepExecutor(definitions: [definition])
        let step = pickleStep("the user enters alice")

        var feature = TestFeature()
        try await executor.execute(step, on: &feature)

        #expect(feature.executedSteps == ["enter"])
        #expect(feature.capturedArgs == [["alice"]])
    }

    @Test("execute propagates handler errors")
    func executeHandlerError() async throws {
        struct StepError: Error {}
        let definition = exactDefinition("fail step") { _, _, _ in
            throw StepError()
        }
        let executor = StepExecutor(definitions: [definition])
        let step = pickleStep("fail step")

        var feature = TestFeature()
        await #expect(throws: StepError.self) {
            try await executor.execute(step, on: &feature)
        }
    }

    @Test("execute throws undefined for unmatched step")
    func executeUndefined() async throws {
        let executor = StepExecutor<TestFeature>(definitions: [])
        let step = pickleStep("missing step")

        var feature = TestFeature()
        await #expect(throws: StepMatchError.self) {
            try await executor.execute(step, on: &feature)
        }
    }

    // MARK: - Multiple Definitions

    @Test("matches the correct definition among multiple")
    func multipleDefinitions() throws {
        let def1 = exactDefinition("step A", line: 1)
        let def2 = exactDefinition("step B", line: 2)
        let def3 = exactDefinition("step C", line: 3)
        let executor = StepExecutor(definitions: [def1, def2, def3])

        let matchB = try executor.match(pickleStep("step B"))
        #expect(matchB.matchLocation == Location(line: 2))

        let matchC = try executor.match(pickleStep("step C"))
        #expect(matchC.matchLocation == Location(line: 3))
    }

    @Test("exact match preferred ordering: first matching definition wins")
    func firstMatchWins() throws {
        let def1 = regexDefinition("^hello (.+)$", line: 1)
        let executor = StepExecutor(definitions: [def1])
        let step = pickleStep("hello world")

        let match = try executor.match(step)
        #expect(match.matchLocation.line == 1)
        #expect(match.arguments == ["world"])
    }

    // MARK: - Edge Cases

    @Test("empty step text")
    func emptyStepText() throws {
        let definition = exactDefinition("")
        let executor = StepExecutor(definitions: [definition])
        let step = pickleStep("")

        let match = try executor.match(step)
        #expect(match.arguments.isEmpty)
    }

    @Test("step with special regex characters in exact match")
    func specialCharsExactMatch() throws {
        let definition = exactDefinition("the price is $9.99 (USD)")
        let executor = StepExecutor(definitions: [definition])
        let step = pickleStep("the price is $9.99 (USD)")

        let match = try executor.match(step)
        #expect(match.arguments.isEmpty)
    }

    @Test("invalid regex pattern does not match")
    func invalidRegexPattern() throws {
        let definition = regexDefinition("[invalid")
        let executor = StepExecutor(definitions: [definition])
        let step = pickleStep("anything")

        #expect(throws: StepMatchError.self) {
            try executor.match(step)
        }
    }

}

// MARK: - Cucumber Expression & Coverage Tests

@Suite("StepExecutor — Cucumber Expressions & Coverage")
struct StepExecutorCoverageTests {

    // MARK: - Cucumber Expression Patterns

    @Test("matches step with cucumber expression pattern")
    func cucumberExpressionMatch() throws {
        let definition = StepDefinition<TestFeature>(
            keywordType: .context,
            pattern: .cucumberExpression("I have {int} items"),
            sourceLocation: Location(line: 1),
            handler: { _, _, _ in }
        )
        let executor = StepExecutor(definitions: [definition])
        let step = pickleStep("I have 42 items")

        let match = try executor.match(step)
        #expect(match.arguments == ["42"])
    }

    @Test("cucumber expression priority over regex")
    func cucumberExpressionPriorityOverRegex() throws {
        let cucumberDef = StepDefinition<TestFeature>(
            keywordType: .context,
            pattern: .cucumberExpression("the user has {int} items"),
            sourceLocation: Location(line: 1),
            handler: { _, _, _ in }
        )
        let regexDef = regexDefinition("^the user has (\\d+) items$", line: 2)
        let executor = StepExecutor(definitions: [cucumberDef, regexDef])
        let step = pickleStep("the user has 5 items")

        let match = try executor.match(step)
        #expect(match.matchLocation == Location(line: 1))
    }

    @Test("exact match priority over cucumber expression")
    func exactPriorityOverCucumberExpression() throws {
        let exactDef = exactDefinition("the user has 5 items", line: 1)
        let cucumberDef = StepDefinition<TestFeature>(
            keywordType: .context,
            pattern: .cucumberExpression("the user has {int} items"),
            sourceLocation: Location(line: 2),
            handler: { _, _, _ in }
        )
        let executor = StepExecutor(definitions: [exactDef, cucumberDef])
        let step = pickleStep("the user has 5 items")

        let match = try executor.match(step)
        #expect(match.matchLocation == Location(line: 1))
        #expect(match.arguments.isEmpty)
    }

    // MARK: - Custom Registry

    @Test("executor with custom parameter type registry")
    func customRegistry() throws {
        var registry = ParameterTypeRegistry()
        try registry.registerAny(
            AnyParameterType(
                name: "color",
                regexps: ["red|green|blue"],
                transformer: { $0 }
            ))
        let definition = StepDefinition<TestFeature>(
            keywordType: .context,
            pattern: .cucumberExpression("the {color} button"),
            sourceLocation: Location(line: 1),
            handler: { _, _, _ in }
        )
        let executor = StepExecutor(definitions: [definition], registry: registry)
        let step = pickleStep("the red button")

        let match = try executor.match(step)
        #expect(match.arguments == ["red"])
    }

    // MARK: - extractCaptures

    @Test("extractCaptures returns capture group strings")
    func extractCaptures() throws {
        let regex = try Regex("^(\\w+) has (\\d+) items$")
        let result = try #require(try regex.wholeMatch(in: "Alice has 5 items"))
        let captures = StepExecutor<TestFeature>.extractCaptures(from: result)
        #expect(captures == ["Alice", "5"])
    }

    @Test("extractCaptures returns empty for no groups")
    func extractCapturesEmpty() throws {
        let regex = try Regex("^hello world$")
        let result = try #require(try regex.wholeMatch(in: "hello world"))
        let captures = StepExecutor<TestFeature>.extractCaptures(from: result)
        #expect(captures.isEmpty)
    }

    // MARK: - StepMatchError Descriptions

    @Test("StepMatchError.undefined errorDescription")
    func undefinedErrorDescription() {
        let error = StepMatchError.undefined(stepText: "missing step")
        let desc = error.errorDescription
        #expect(desc?.contains("Undefined step") == true)
        #expect(desc?.contains("missing step") == true)
    }

    @Test("StepMatchError.ambiguous errorDescription")
    func ambiguousErrorDescription() {
        let error = StepMatchError.ambiguous(
            stepText: "the step",
            matchDescriptions: ["pattern A", "pattern B"]
        )
        let desc = error.errorDescription
        #expect(desc?.contains("Ambiguous step") == true)
        #expect(desc?.contains("pattern A") == true)
        #expect(desc?.contains("pattern B") == true)
    }

    @Test("StepMatchError.typeMismatch errorDescription")
    func typeMismatchErrorDescription() {
        let error = StepMatchError.typeMismatch(
            stepText: "I have abc items",
            expected: "Int",
            actual: "abc"
        )
        let desc = error.errorDescription
        #expect(desc?.contains("Type mismatch") == true)
        #expect(desc?.contains("Int") == true)
        #expect(desc?.contains("abc") == true)
    }
}
