// PickleCompilerExtraTests.swift
// GherkinTestingTests
//
// Copyright © 2026 Atelier Socle. MIT License.

import Testing

@testable import GherkinTesting

@Suite("PickleCompiler — Rule Tests")
struct PickleCompilerRuleTests {

    let compiler = PickleCompiler()
    let parser = GherkinParser()

    @Test("Rule scenario gets feature and rule backgrounds")
    func ruleScenario() throws {
        let source = """
            Feature: Rules
              Background:
                Given feature bg

              Rule: R1
                Background:
                  Given rule bg

                Scenario: S1
                  When action
            """
        let doc = try parser.parse(source: source)
        let pickles = compiler.compile(doc)
        #expect(pickles.count == 1)
        #expect(pickles[0].steps.count == 3)
        #expect(pickles[0].steps[0].text == "feature bg")
        #expect(pickles[0].steps[1].text == "rule bg")
        #expect(pickles[0].steps[2].text == "action")
    }

    @Test("Feature-level and rule-level scenarios mixed")
    func mixedScenarios() throws {
        let source = """
            Feature: Mixed
              Scenario: Feature level
                Given feature step

              Rule: R1
                Scenario: Rule level
                  Given rule step
            """
        let doc = try parser.parse(source: source)
        let pickles = compiler.compile(doc)
        #expect(pickles.count == 2)
        #expect(pickles[0].name == "Feature level")
        #expect(pickles[1].name == "Rule level")
    }
}

@Suite("PickleCompiler — Lazy Sequence Tests")
struct PickleCompilerLazyTests {

    let compiler = PickleCompiler()
    let parser = GherkinParser()

    @Test("compileSequence yields same results as compile")
    func sequenceEqualsArray() throws {
        let source = """
            Feature: Lazy
              Background:
                Given bg

              Scenario: S1
                Given step 1

              Scenario Outline: SO
                Given <x>

                Examples:
                  | x |
                  | a |
                  | b |
            """
        let doc = try parser.parse(source: source)
        let arrayResult = compiler.compile(doc)
        let seqResult = Array(compiler.compileSequence(doc))
        #expect(arrayResult.count == seqResult.count)
        for (a, b) in zip(arrayResult, seqResult) {
            #expect(a.name == b.name)
            #expect(a.steps.count == b.steps.count)
            #expect(a.tags.count == b.tags.count)
        }
    }

    @Test("100K examples expansion completes without crash")
    func largeExpansion() throws {
        // Build a feature with a Scenario Outline and 100K rows
        var rows = "| x |\n"
        for i in 0..<100_000 {
            rows += "| \(i) |\n"
        }
        let source = """
            Feature: Large
              Scenario Outline: SO
                Given <x>

                Examples:
            \(rows)
            """

        let doc = try parser.parse(source: source)

        // Use lazy sequence to avoid materializing all pickles
        let clock = ContinuousClock()
        var count = 0
        let elapsed = clock.measure {
            for _ in compiler.compileSequence(doc) {
                count += 1
            }
        }

        #expect(count == 100_000)
        #expect(elapsed < .seconds(5))
    }
}
