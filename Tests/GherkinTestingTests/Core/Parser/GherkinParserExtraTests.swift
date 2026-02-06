// GherkinParserExtraTests.swift
// GherkinTestingTests
//
// Copyright © 2026 Atelier Socle. MIT License.

import Testing

@testable import GherkinTesting

@Suite("GherkinParser — Tag Tests")
struct ParserTagTests {

    @Test("Multiple tags on one line")
    func multipleTagsOneLine() throws {
        let source = """
            @tag1 @tag2 @tag3
            Feature: Tagged
              Scenario: S1
                Given step
            """
        let doc = try GherkinParser().parse(source: source)
        let feature = try #require(doc.feature)
        #expect(feature.tags.count == 3)
    }

    @Test("Scenario tags")
    func scenarioTags() throws {
        let source = """
            Feature: F1
              @smoke
              Scenario: S1
                Given step
            """
        let doc = try GherkinParser().parse(source: source)
        let scenario = try #require(doc.feature?.scenarios.first)
        #expect(scenario.tags.count == 1)
        #expect(scenario.tags[0].name == "@smoke")
    }
}

@Suite("GherkinParser — Comment Tests")
struct ParserCommentTests {

    @Test("Comments are preserved in document")
    func commentsPreserved() throws {
        let source = """
            # File comment
            Feature: F1
              # Section comment
              Scenario: S1
                Given step
            """
        let doc = try GherkinParser().parse(source: source)
        #expect(doc.comments.count >= 1)
        #expect(doc.comments[0].text.contains("File comment"))
    }

    @Test("Language directive is excluded from comments")
    func languageDirectiveNotInComments() throws {
        let source = """
            # language: fr
            Fonctionnalité: Test
              Scénario: S1
                Soit un truc
            """
        let doc = try GherkinParser().parse(source: source)
        // The # language: directive should NOT appear in comments
        let hasLanguageComment = doc.comments.contains { $0.text.contains("language") }
        #expect(!hasLanguageComment)
    }
}

@Suite("GherkinParser — Edge Cases")
struct ParserEdgeCaseTests {

    @Test("Empty scenario name")
    func emptyScenarioName() throws {
        let source = """
            Feature: Edge
              Scenario:
                Given step
            """
        let doc = try GherkinParser().parse(source: source)
        let scenario = try #require(doc.feature?.scenarios.first)
        #expect(scenario.name == "")
    }

    @Test("Unicode in step text")
    func unicodeStepText() throws {
        let source = """
            Feature: Unicode
              Scenario: Unicode test
                Given café résumé naïve 日本語
            """
        let doc = try GherkinParser().parse(source: source)
        let step = try #require(doc.feature?.scenarios[0].steps.first)
        #expect(step.text.contains("café"))
        #expect(step.text.contains("日本語"))
    }

    @Test("Feature with no scenarios")
    func featureNoScenarios() throws {
        let source = "Feature: Empty feature"
        let doc = try GherkinParser().parse(source: source)
        let feature = try #require(doc.feature)
        #expect(feature.scenarios.isEmpty)
        #expect(feature.rules.isEmpty)
        #expect(feature.children.isEmpty)
    }

    @Test("Scenario with no steps")
    func scenarioNoSteps() throws {
        let source = """
            Feature: Empty steps
              Scenario: No steps
            """
        let doc = try GherkinParser().parse(source: source)
        let scenario = try #require(doc.feature?.scenarios.first)
        #expect(scenario.steps.isEmpty)
    }

    @Test("Mixed scenarios and rules preserve order in children")
    func mixedScenariosAndRules() throws {
        let source = """
            Feature: Mixed
              Scenario: Direct scenario
                Given step

              Rule: A rule
                Scenario: Rule scenario
                  Given step
            """
        let doc = try GherkinParser().parse(source: source)
        let feature = try #require(doc.feature)
        #expect(feature.scenarios.count == 1)
        #expect(feature.rules.count == 1)
        #expect(feature.rules[0].scenarios.count == 1)
        #expect(feature.children.count == 2)
        if case .scenario = feature.children[0] {} else { Issue.record("Expected scenario at index 0") }
        if case .rule = feature.children[1] {} else { Issue.record("Expected rule at index 1") }
    }
}

@Suite("GherkinParser — i18n Tests")
struct ParserI18nTests {

    @Test("Parse French feature")
    func frenchFeature() throws {
        let source = """
            # language: fr
            Fonctionnalité: Authentification
              Scénario: Connexion réussie
                Soit un utilisateur enregistré
                Quand il entre ses identifiants
                Alors il voit le tableau de bord
            """
        let doc = try GherkinParser().parse(source: source)
        let feature = try #require(doc.feature)
        #expect(feature.name == "Authentification")
        #expect(feature.language == "fr")
        #expect(feature.keyword == "Fonctionnalité")
        #expect(feature.scenarios.count == 1)
        #expect(feature.scenarios[0].steps.count == 3)
    }

    @Test("Parse Japanese feature")
    func japaneseFeature() throws {
        let source = """
            # language: ja
            フィーチャ: ログイン機能
              シナリオ: 正常なログイン
                前提 ユーザーが登録されている
                もし ユーザーがログインする
                ならば ダッシュボードが表示される
            """
        let doc = try GherkinParser().parse(source: source)
        let feature = try #require(doc.feature)
        #expect(feature.name == "ログイン機能")
        #expect(feature.language == "ja")
        #expect(feature.scenarios.count == 1)
        #expect(feature.scenarios[0].steps.count == 3)
    }
}

// MARK: - GherkinParser — Additional Coverage

@Suite("GherkinParser — Additional Coverage")
struct GherkinParserCoverageTests {

    @Test("empty source produces no feature")
    func emptySource() throws {
        let doc = try GherkinParser().parse(source: "")
        #expect(doc.feature == nil)
    }

    @Test("only comments, no feature")
    func onlyComments() throws {
        let source = """
            # Just a comment
            # Another comment
            """
        let doc = try GherkinParser().parse(source: source)
        #expect(doc.feature == nil)
        #expect(doc.comments.count >= 2)
    }

    @Test("feature description is parsed")
    func featureDescription() throws {
        let source = """
            Feature: With description
              This is a description
              spanning multiple lines

              Scenario: S1
                Given step
            """
        let doc = try GherkinParser().parse(source: source)
        let feature = try #require(doc.feature)
        #expect(feature.description?.contains("description") == true)
        #expect(feature.description?.contains("spanning") == true)
    }

    @Test("duplicate background throws error")
    func duplicateBackground() throws {
        let source = """
            Feature: Bad
              Background:
                Given first
              Background:
                Given second
            """
        #expect(throws: ParserError.self) {
            try GherkinParser().parse(source: source)
        }
    }

    @Test("duplicate background in rule throws error")
    func duplicateBackgroundInRule() throws {
        let source = """
            Feature: Bad
              Rule: R1
                Background:
                  Given first
                Background:
                  Given second
            """
        #expect(throws: ParserError.self) {
            try GherkinParser().parse(source: source)
        }
    }

    @Test("wildcard step keyword resolves to unknown")
    func wildcardStepKeyword() throws {
        let source = """
            Feature: Wildcard
              Scenario: S
                * step with wildcard
            """
        let doc = try GherkinParser().parse(source: source)
        let step = try #require(doc.feature?.scenarios[0].steps.first)
        #expect(step.keywordType == .unknown)
    }

    @Test("And inherits previous step keyword type")
    func andInheritsType() throws {
        let source = """
            Feature: Inherit
              Scenario: S
                Given first
                And second
            """
        let doc = try GherkinParser().parse(source: source)
        let steps = doc.feature?.scenarios[0].steps ?? []
        #expect(steps[0].keywordType == .context)
        #expect(steps[1].keywordType == .context)
    }

    @Test("But inherits previous step keyword type")
    func butInheritsType() throws {
        let source = """
            Feature: Inherit
              Scenario: S
                When action
                But exception
            """
        let doc = try GherkinParser().parse(source: source)
        let steps = doc.feature?.scenarios[0].steps ?? []
        #expect(steps[0].keywordType == .action)
        #expect(steps[1].keywordType == .action)
    }

    @Test("tag followed by rule correctly scoped")
    func tagFollowedByRule() throws {
        let source = """
            Feature: Tag Rule
              Scenario: Before rule
                Given step

              @rule-tag
              Rule: Tagged rule
                Scenario: In rule
                  Given step
            """
        let doc = try GherkinParser().parse(source: source)
        let feature = try #require(doc.feature)
        #expect(feature.scenarios.count == 1)
        #expect(feature.rules.count == 1)
        #expect(feature.rules[0].tags.count == 1)
        #expect(feature.rules[0].tags[0].name == "@rule-tag")
    }

    @Test("scenario outline with tagged examples")
    func outlineWithTaggedExamples() throws {
        let source = """
            Feature: Outline
              Scenario Outline: O
                Given I have <count> items

                @data
                Examples:
                  | count |
                  | 1     |
                  | 2     |
            """
        let doc = try GherkinParser().parse(source: source)
        let scenario = try #require(doc.feature?.scenarios.first)
        #expect(scenario.examples.count == 1)
        #expect(scenario.examples[0].tags.count == 1)
        #expect(scenario.examples[0].tags[0].name == "@data")
    }

    @Test("scenario outline with multiple examples")
    func outlineMultipleExamples() throws {
        let source = """
            Feature: Multi Examples
              Scenario Outline: O
                Given I have <count> items

                Examples: First set
                  | count |
                  | 1     |

                Examples: Second set
                  | count |
                  | 2     |
            """
        let doc = try GherkinParser().parse(source: source)
        let scenario = try #require(doc.feature?.scenarios.first)
        #expect(scenario.examples.count == 2)
        #expect(scenario.examples[0].name == "First set")
        #expect(scenario.examples[1].name == "Second set")
    }

    @Test("background with steps")
    func backgroundWithSteps() throws {
        let source = """
            Feature: BG
              Background:
                Given common step

              Scenario: S
                Then check
            """
        let doc = try GherkinParser().parse(source: source)
        let feature = try #require(doc.feature)
        let bg = try #require(feature.background)
        #expect(bg.steps.count == 1)
        #expect(bg.steps[0].text == "common step")
    }

    @Test("non-feature content is skipped gracefully")
    func nonFeatureContent() throws {
        let source = """
            This is just random text
            that does not contain a Feature keyword
            """
        let doc = try GherkinParser().parse(source: source)
        #expect(doc.feature == nil)
    }
}
