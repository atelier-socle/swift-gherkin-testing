// GherkinParserTests.swift
// GherkinTestingTests
//
// Copyright © 2026 Atelier Socle. MIT License.

import Testing

@testable import GherkinTesting

@Suite("GherkinParser — Feature Tests")
struct ParserFeatureTests {

    @Test("Parse simple feature")
    func simpleFeature() throws {
        let source = """
            Feature: Login
              As a user I want to log in.

              Scenario: Valid login
                Given valid credentials
                When I log in
                Then I see the dashboard
            """
        let doc = try GherkinParser().parse(source: source)
        let feature = try #require(doc.feature)
        #expect(feature.name == "Login")
        #expect(feature.keyword == "Feature")
        #expect(feature.language == "en")
        #expect(feature.scenarios.count == 1)
        #expect(feature.scenarios[0].name == "Valid login")
        #expect(feature.scenarios[0].steps.count == 3)
    }

    @Test("Parse feature with tags")
    func featureWithTags() throws {
        let source = """
            @smoke @login
            Feature: Tagged feature
              Scenario: S1
                Given step
            """
        let doc = try GherkinParser().parse(source: source)
        let feature = try #require(doc.feature)
        #expect(feature.tags.count == 2)
        #expect(feature.tags[0].name == "@smoke")
        #expect(feature.tags[1].name == "@login")
    }

    @Test("Parse feature with description")
    func featureWithDescription() throws {
        let source = """
            Feature: Described
              As a user
              I want to do things
              So that I can achieve goals

              Scenario: S1
                Given step
            """
        let doc = try GherkinParser().parse(source: source)
        let feature = try #require(doc.feature)
        let desc = try #require(feature.description)
        #expect(desc.contains("As a user"))
        #expect(desc.contains("I want to do things"))
    }

    @Test("Parse empty document")
    func emptyDocument() throws {
        let doc = try GherkinParser().parse(source: "")
        #expect(doc.feature == nil)
        #expect(doc.comments.isEmpty)
    }

    @Test("Parse document with only comments")
    func onlyComments() throws {
        let source = """
            # Comment 1
            # Comment 2
            """
        let doc = try GherkinParser().parse(source: source)
        #expect(doc.feature == nil)
        #expect(doc.comments.count == 2)
    }

    @Test("Parse feature with multiple scenarios")
    func multipleScenarios() throws {
        let source = """
            Feature: Multi
              Scenario: S1
                Given step1
              Scenario: S2
                Given step2
              Scenario: S3
                Given step3
            """
        let doc = try GherkinParser().parse(source: source)
        let feature = try #require(doc.feature)
        #expect(feature.scenarios.count == 3)
        #expect(feature.scenarios[0].name == "S1")
        #expect(feature.scenarios[1].name == "S2")
        #expect(feature.scenarios[2].name == "S3")
    }
}

@Suite("GherkinParser — Background Tests")
struct ParserBackgroundTests {

    @Test("Parse feature with background")
    func featureWithBackground() throws {
        let source = """
            Feature: BG test
              Background:
                Given the app is running
                And the DB is clean

              Scenario: S1
                When action
                Then result
            """
        let doc = try GherkinParser().parse(source: source)
        let feature = try #require(doc.feature)
        let bg = try #require(feature.background)
        #expect(bg.steps.count == 2)
        #expect(bg.steps[0].keyword == "Given ")
        #expect(bg.steps[1].keyword == "And ")
    }

    @Test("Background with name")
    func backgroundWithName() throws {
        let source = """
            Feature: BG named
              Background: Setup
                Given setup step
              Scenario: S1
                When action
            """
        let doc = try GherkinParser().parse(source: source)
        let bg = try #require(doc.feature?.background)
        #expect(bg.name == "Setup")
    }
}

@Suite("GherkinParser — Step Tests")
struct ParserStepTests {

    @Test("And resolves to Given type")
    func andResolvesToGiven() throws {
        let source = """
            Feature: Step types
              Scenario: S1
                Given first
                And second
            """
        let doc = try GherkinParser().parse(source: source)
        let steps = doc.feature?.scenarios[0].steps ?? []
        #expect(steps[0].keywordType == .context)
        #expect(steps[1].keywordType == .context)  // And inherits Given's type
    }

    @Test("But resolves to When type")
    func butResolvesToWhen() throws {
        let source = """
            Feature: Step types
              Scenario: S1
                When action
                But not this
            """
        let doc = try GherkinParser().parse(source: source)
        let steps = doc.feature?.scenarios[0].steps ?? []
        #expect(steps[0].keywordType == .action)
        #expect(steps[1].keywordType == .action)  // But inherits When's type
    }

    @Test("And after Then resolves to outcome")
    func andAfterThen() throws {
        let source = """
            Feature: Step types
              Scenario: S1
                Then result
                And more result
            """
        let doc = try GherkinParser().parse(source: source)
        let steps = doc.feature?.scenarios[0].steps ?? []
        #expect(steps[0].keywordType == .outcome)
        #expect(steps[1].keywordType == .outcome)
    }

    @Test("Wildcard step resolves to unknown per spec")
    func wildcardStep() throws {
        let source = """
            Feature: Wildcards
              Scenario: S1
                Given setup
                * more setup
                When action
                * more action
            """
        let doc = try GherkinParser().parse(source: source)
        let steps = doc.feature?.scenarios[0].steps ?? []
        #expect(steps[0].keywordType == .context)
        #expect(steps[1].keywordType == .unknown)  // * is always .unknown per spec
        #expect(steps[2].keywordType == .action)
        #expect(steps[3].keywordType == .unknown)  // * is always .unknown per spec
    }

    @Test("Given When Then sequence")
    func givenWhenThenSequence() throws {
        let source = """
            Feature: Full
              Scenario: S1
                Given precondition
                When action
                Then outcome
            """
        let doc = try GherkinParser().parse(source: source)
        let steps = doc.feature?.scenarios[0].steps ?? []
        #expect(steps[0].keywordType == .context)
        #expect(steps[0].keyword == "Given ")
        #expect(steps[1].keywordType == .action)
        #expect(steps[1].keyword == "When ")
        #expect(steps[2].keywordType == .outcome)
        #expect(steps[2].keyword == "Then ")
    }
}

@Suite("GherkinParser — Scenario Outline Tests")
struct ParserScenarioOutlineTests {

    @Test("Parse scenario outline with examples")
    func scenarioOutline() throws {
        let source = """
            Feature: Outline
              Scenario Outline: Eating
                Given there are <start> cucumbers
                When I eat <eat> cucumbers
                Then I should have <left> cucumbers

                Examples:
                  | start | eat | left |
                  |    12 |   5 |    7 |
                  |    20 |   5 |   15 |
            """
        let doc = try GherkinParser().parse(source: source)
        let scenario = try #require(doc.feature?.scenarios.first)
        #expect(scenario.keyword == "Scenario Outline")
        #expect(scenario.examples.count == 1)
        let ex = scenario.examples[0]
        let header = try #require(ex.tableHeader)
        #expect(header.cells.count == 3)
        #expect(header.cells[0].value == "start")
        #expect(ex.tableBody.count == 2)
    }

    @Test("Multiple examples blocks")
    func multipleExamples() throws {
        let source = """
            Feature: Multi examples
              Scenario Outline: Test
                Given <value>

                Examples: First
                  | value |
                  | a     |

                Examples: Second
                  | value |
                  | b     |
                  | c     |
            """
        let doc = try GherkinParser().parse(source: source)
        let scenario = try #require(doc.feature?.scenarios.first)
        #expect(scenario.examples.count == 2)
        #expect(scenario.examples[0].name == "First")
        #expect(scenario.examples[0].tableBody.count == 1)
        #expect(scenario.examples[1].name == "Second")
        #expect(scenario.examples[1].tableBody.count == 2)
    }

    @Test("Tagged examples")
    func taggedExamples() throws {
        let source = """
            Feature: Tagged examples
              Scenario Outline: Test
                Given <x>

                @positive
                Examples:
                  | x |
                  | 1 |

                @negative
                Examples:
                  | x  |
                  | -1 |
            """
        let doc = try GherkinParser().parse(source: source)
        let scenario = try #require(doc.feature?.scenarios.first)
        #expect(scenario.examples[0].tags.count == 1)
        #expect(scenario.examples[0].tags[0].name == "@positive")
        #expect(scenario.examples[1].tags[0].name == "@negative")
    }

    @Test("Examples with no name have nil name")
    func examplesNoName() throws {
        let source = """
            Feature: Unnamed examples
              Scenario Outline: Test
                Given <x>

                Examples:
                  | x |
                  | 1 |
            """
        let doc = try GherkinParser().parse(source: source)
        let ex = try #require(doc.feature?.scenarios.first?.examples.first)
        #expect(ex.name == nil)
    }
}

@Suite("GherkinParser — Rule Tests")
struct ParserRuleTests {

    @Test("Parse feature with rules")
    func featureWithRules() throws {
        let source = """
            Feature: Rules
              Rule: First rule
                Scenario: R1S1
                  Given step

              Rule: Second rule
                Scenario: R2S1
                  Given step
            """
        let doc = try GherkinParser().parse(source: source)
        let feature = try #require(doc.feature)
        #expect(feature.rules.count == 2)
        #expect(feature.rules[0].name == "First rule")
        #expect(feature.rules[1].name == "Second rule")
    }

    @Test("Rule with background")
    func ruleWithBackground() throws {
        let source = """
            Feature: Rules with BG
              Rule: My rule
                Background:
                  Given rule setup

                Scenario: S1
                  When action
                  Then result
            """
        let doc = try GherkinParser().parse(source: source)
        let rule = try #require(doc.feature?.rules.first)
        let bg = try #require(rule.background)
        #expect(bg.steps.count == 1)
        #expect(rule.scenarios.count == 1)
    }

    @Test("Tagged rules")
    func taggedRules() throws {
        let source = """
            Feature: Tagged rules
              @billing
              Rule: Billing
                Scenario: S1
                  Given step
            """
        let doc = try GherkinParser().parse(source: source)
        let rule = try #require(doc.feature?.rules.first)
        #expect(rule.tags.count == 1)
        #expect(rule.tags[0].name == "@billing")
    }

    @Test("Children preserve source order")
    func childrenOrder() throws {
        let source = """
            Feature: Ordered
              Background:
                Given setup

              Scenario: S1
                Given step

              Rule: R1
                Scenario: RS1
                  Given step
            """
        let doc = try GherkinParser().parse(source: source)
        let feature = try #require(doc.feature)
        #expect(feature.children.count == 3)
        if case .background = feature.children[0] {} else { Issue.record("Expected background at index 0") }
        if case .scenario = feature.children[1] {} else { Issue.record("Expected scenario at index 1") }
        if case .rule = feature.children[2] {} else { Issue.record("Expected rule at index 2") }
    }
}

@Suite("GherkinParser — DataTable Tests")
struct ParserDataTableTests {

    @Test("Step with data table")
    func stepWithDataTable() throws {
        let source = """
            Feature: Tables
              Scenario: S1
                Given these users:
                  | name  | email           |
                  | Alice | alice@test.com  |
                  | Bob   | bob@test.com    |
            """
        let doc = try GherkinParser().parse(source: source)
        let step = try #require(doc.feature?.scenarios[0].steps.first)
        let table = try #require(step.dataTable)
        #expect(table.rows.count == 3)  // header + 2 data rows
        #expect(table.rows[0].cells[0].value == "name")
        #expect(table.rows[1].cells[0].value == "Alice")
    }
}

@Suite("GherkinParser — DocString Tests")
struct ParserDocStringTests {

    @Test("Step with doc string")
    func stepWithDocString() throws {
        let source = """
            Feature: DocStrings
              Scenario: S1
                Given the following text:
                  \"\"\"
                  Hello World
                  Second line
                  \"\"\"
            """
        let doc = try GherkinParser().parse(source: source)
        let step = try #require(doc.feature?.scenarios[0].steps.first)
        let ds = try #require(step.docString)
        #expect(ds.delimiter == "\"\"\"")
        #expect(ds.content.contains("Hello World"))
        #expect(ds.content.contains("Second line"))
        #expect(ds.mediaType == nil)
    }

    @Test("Doc string with media type")
    func docStringMediaType() throws {
        let source = """
            Feature: DocStrings
              Scenario: S1
                Given JSON payload:
                  ```json
                  {"key": "value"}
                  ```
            """
        let doc = try GherkinParser().parse(source: source)
        let step = try #require(doc.feature?.scenarios[0].steps.first)
        let ds = try #require(step.docString)
        #expect(ds.delimiter == "```")
        #expect(ds.mediaType == "json")
        #expect(ds.content.contains("\"key\""))
    }
}
