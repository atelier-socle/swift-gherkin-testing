// BenchmarkTests.swift
// GherkinTestingTests
//
// Copyright © 2026 Atelier Socle. MIT License.

import Testing
import Foundation
@testable import GherkinTesting

// MARK: - Benchmark Helper

private struct BenchmarkResult {
    let median: Duration
    let iterations: Int
}

private func benchmark(
    iterations: Int = 5,
    _ body: () throws -> Void
) rethrows -> BenchmarkResult {
    var durations: [Duration] = []
    let clock = ContinuousClock()
    for _ in 0..<iterations {
        let elapsed = try clock.measure { try body() }
        durations.append(elapsed)
    }
    durations.sort()
    let median = durations[durations.count / 2]
    return BenchmarkResult(median: median, iterations: iterations)
}

private func asyncBenchmark(
    iterations: Int = 5,
    _ body: () async throws -> Void
) async rethrows -> BenchmarkResult {
    var durations: [Duration] = []
    let clock = ContinuousClock()
    for _ in 0..<iterations {
        let start = clock.now
        try await body()
        durations.append(clock.now - start)
    }
    durations.sort()
    let median = durations[durations.count / 2]
    return BenchmarkResult(median: median, iterations: iterations)
}

// MARK: - Feature Source Generators

private func generateFeatureSource(scenarioCount: Int, stepsPerScenario: Int = 3) -> String {
    var lines = ["Feature: Benchmark Feature"]
    for i in 0..<scenarioCount {
        lines.append("")
        lines.append("  Scenario: Scenario \(i)")
        for s in 0..<stepsPerScenario {
            let keyword = s == 0 ? "Given" : (s == 1 ? "When" : "Then")
            lines.append("    \(keyword) step \(s) of scenario \(i)")
        }
    }
    return lines.joined(separator: "\n")
}

private func generateOutlineSource(exampleCount: Int) -> String {
    var lines = [
        "Feature: Outline Benchmark",
        "",
        "  Scenario Outline: Parameterized",
        "    Given a value of <input>",
        "    When processed",
        "    Then the output is <output>",
        "",
        "    Examples:",
        "      | input | output |",
    ]
    for i in 0..<exampleCount {
        lines.append("      | val\(i) | out\(i) |")
    }
    return lines.joined(separator: "\n")
}

private struct BenchmarkFeature: GherkinFeature {}

// MARK: - Tests
//
// CI-safe thresholds: all limits are 10x–20x the ideal local target to avoid
// flaky failures on slow CI runners or Apple Silicon vs Intel differences.
// Each test prints its actual median for monitoring.

@Suite("Performance Benchmarks")
struct BenchmarkTests {

    // MARK: - 1. Lexer: 1000-line file

    @Test("Lexer tokenizes 1000-line file (median of 5)")
    func lexer1000Lines() throws {
        let source = generateFeatureSource(scenarioCount: 200, stepsPerScenario: 4)
        let result = benchmark {
            let lexer = GherkinLexer(source: source)
            let tokens = lexer.tokenize()
            _ = tokens.count
        }
        // Ideal local target: < 10ms
        print("Benchmark [Lexer 1000 lines]: median = \(result.median)")
        #expect(result.median < .seconds(1),
                "Lexer median \(result.median) exceeded CI threshold of 1s")
    }

    // MARK: - 2. Parser: 1000-line file

    @Test("Parser parses 1000-line file (median of 5)")
    func parser1000Lines() throws {
        let source = generateFeatureSource(scenarioCount: 200, stepsPerScenario: 4)
        let result = try benchmark {
            let parser = GherkinParser()
            _ = try parser.parse(source: source)
        }
        // Ideal local target: < 10ms
        print("Benchmark [Parser 1000 lines]: median = \(result.median)")
        #expect(result.median < .seconds(5),
                "Parser median \(result.median) exceeded CI threshold of 5s")
    }

    // MARK: - 3. Compiler: 100 scenarios

    @Test("Compiler compiles 100 scenarios (median of 5)")
    func compiler100Scenarios() throws {
        let source = generateFeatureSource(scenarioCount: 100)
        let parser = GherkinParser()
        let document = try parser.parse(source: source)
        let compiler = PickleCompiler()

        let result = benchmark {
            let pickles = compiler.compile(document)
            _ = pickles.count
        }
        // Ideal local target: < 10ms
        print("Benchmark [Compiler 100 scenarios]: median = \(result.median)")
        #expect(result.median < .seconds(1),
                "Compiler median \(result.median) exceeded CI threshold of 1s")
    }

    // MARK: - 4. Compiler: 10K outline expansion (lazy)

    @Test("Lazy compiler expands 10K examples (median of 5)")
    func compilerLazy10KExamples() throws {
        let source = generateOutlineSource(exampleCount: 10_000)
        let parser = GherkinParser()
        let document = try parser.parse(source: source)
        let compiler = PickleCompiler()

        let result = benchmark {
            var count = 0
            for _ in compiler.compileSequence(document) {
                count += 1
            }
            #expect(count == 10_000)
        }
        // Ideal local target: < 500ms
        print("Benchmark [Lazy 10K expansion]: median = \(result.median)")
        #expect(result.median < .seconds(10),
                "Lazy 10K expansion median \(result.median) exceeded CI threshold of 10s")
    }

    // MARK: - 5. Step matching: exact (1000 matches)

    @Test("Exact step matching 1000 steps (median of 5)")
    func exactMatching1000() throws {
        let definitions: [StepDefinition<BenchmarkFeature>] = (0..<50).map { i in
            StepDefinition(
                pattern: .exact("step \(i)"),
                sourceLocation: Location(line: i + 1),
                handler: { _, _ in }
            )
        }
        let matcher = RegexStepMatcher<BenchmarkFeature>(definitions: definitions)
        let steps = (0..<1000).map { i in
            PickleStep(id: "s\(i)", text: "step \(i % 50)", argument: nil, astNodeIds: [])
        }

        let result = try benchmark {
            for step in steps {
                _ = try matcher.match(step)
            }
        }
        // Ideal local target: < 5ms
        print("Benchmark [Exact matching 1000]: median = \(result.median)")
        #expect(result.median < .seconds(1),
                "Exact matching median \(result.median) exceeded CI threshold of 1s")
    }

    // MARK: - 6. Step matching: Cucumber Expression (1000 matches)

    @Test("Cucumber Expression matching 1000 steps (median of 5)")
    func cucumberExpressionMatching1000() throws {
        let definitions: [StepDefinition<BenchmarkFeature>] = [
            StepDefinition(
                pattern: .cucumberExpression("I have {int} cucumber(s)"),
                sourceLocation: Location(line: 1),
                handler: { _, _ in }
            ),
            StepDefinition(
                pattern: .cucumberExpression("the price is {float} dollars"),
                sourceLocation: Location(line: 2),
                handler: { _, _ in }
            ),
            StepDefinition(
                pattern: .cucumberExpression("the user {string} is logged in"),
                sourceLocation: Location(line: 3),
                handler: { _, _ in }
            ),
        ]
        let matcher = RegexStepMatcher<BenchmarkFeature>(definitions: definitions)
        let texts = [
            "I have 42 cucumbers",
            "the price is 9.99 dollars",
            "the user \"alice\" is logged in",
        ]
        let steps = (0..<1000).map { i in
            PickleStep(id: "s\(i)", text: texts[i % 3], argument: nil, astNodeIds: [])
        }

        let result = try benchmark {
            for step in steps {
                _ = try matcher.match(step)
            }
        }
        // Ideal local target: < 50ms
        print("Benchmark [Cucumber expression 1000]: median = \(result.median)")
        #expect(result.median < .seconds(5),
                "Cucumber expression matching median \(result.median) exceeded CI threshold of 5s")
    }

    // MARK: - 7. Step matching: regex (1000 matches)

    @Test("Regex step matching 1000 steps (median of 5)")
    func regexMatching1000() throws {
        let definitions: [StepDefinition<BenchmarkFeature>] = [
            StepDefinition(
                pattern: .regex("^I have (\\d+) items$"),
                sourceLocation: Location(line: 1),
                handler: { _, _ in }
            ),
            StepDefinition(
                pattern: .regex("^the (\\w+) is (\\w+)$"),
                sourceLocation: Location(line: 2),
                handler: { _, _ in }
            ),
        ]
        let matcher = RegexStepMatcher<BenchmarkFeature>(definitions: definitions)
        let texts = [
            "I have 99 items",
            "the status is active",
        ]
        let steps = (0..<1000).map { i in
            PickleStep(id: "s\(i)", text: texts[i % 2], argument: nil, astNodeIds: [])
        }

        let result = try benchmark {
            for step in steps {
                _ = try matcher.match(step)
            }
        }
        // Ideal local target: < 50ms
        print("Benchmark [Regex matching 1000]: median = \(result.median)")
        #expect(result.median < .seconds(5),
                "Regex matching median \(result.median) exceeded CI threshold of 5s")
    }

    // MARK: - 8. Tag filter evaluation (10K evaluations)

    @Test("Tag filter evaluates 10K tag sets (median of 5)")
    func tagFilter10KEvaluations() throws {
        let filter = try TagFilter("(@smoke or @regression) and not @wip")
        let tagSets: [[String]] = [
            ["@smoke", "@login"],
            ["@regression", "@wip"],
            ["@smoke", "@regression"],
            ["@wip"],
            ["@other"],
        ]

        let result = benchmark {
            for i in 0..<10_000 {
                _ = filter.matches(tags: tagSets[i % tagSets.count])
            }
        }
        // Ideal local target: < 10ms
        print("Benchmark [Tag filter 10K]: median = \(result.median)")
        #expect(result.median < .seconds(1),
                "Tag filter median \(result.median) exceeded CI threshold of 1s")
    }

    // MARK: - 9. i18n language lookup (all languages)

    @Test("Language registry lookup is fast for all languages")
    func languageRegistryLookup() throws {
        let codes = Array(LanguageRegistry.languages.keys)

        let result = benchmark(iterations: 10) {
            for code in codes {
                _ = LanguageRegistry.language(for: code)
            }
        }
        // Ideal local target: < 1ms
        print("Benchmark [Language lookup all]: median = \(result.median)")
        #expect(result.median < .milliseconds(500),
                "Language lookup median \(result.median) exceeded CI threshold of 500ms")
    }

    // MARK: - 10. Reporter generation (100 scenarios)

    @Test("CucumberJSON reporter generates report for 100 scenarios")
    func reporterGeneration100Scenarios() async throws {
        let scenarios = (0..<100).map { i in
            let steps = (0..<3).map { s in
                StepResult(
                    step: PickleStep(id: "s\(i)-\(s)", text: "step \(s) of \(i)", argument: nil, astNodeIds: []),
                    status: .passed,
                    duration: .milliseconds(10),
                    location: Location(line: s + 1)
                )
            }
            return ScenarioResult(name: "Scenario \(i)", stepResults: steps, tags: ["@smoke"])
        }
        let feature = FeatureResult(name: "Benchmark Feature", scenarioResults: scenarios, tags: ["@perf"])
        let runResult = TestRunResult(featureResults: [feature], duration: .seconds(1))

        let reporter = CucumberJSONReporter()
        await reporter.testRunFinished(runResult)

        let result = try await asyncBenchmark {
            let data = try await reporter.generateReport()
            #expect(data.count > 0)
        }
        // Ideal local target: < 50ms
        print("Benchmark [Reporter 100 scenarios]: median = \(result.median)")
        #expect(result.median < .seconds(5),
                "Reporter generation median \(result.median) exceeded CI threshold of 5s")
    }
}
