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
