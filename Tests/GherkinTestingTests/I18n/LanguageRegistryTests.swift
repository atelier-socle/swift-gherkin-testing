// LanguageRegistryTests.swift
// GherkinTestingTests
//
// Copyright © 2026 Atelier Socle. MIT License.

import Testing

@testable import GherkinTesting

@Suite("LanguageRegistry Tests")
struct LanguageRegistryTests {

    @Test("English language is loaded")
    func englishLoaded() {
        let english = LanguageRegistry.language(for: "en")
        #expect(english != nil)
        #expect(english?.name == "English")
        #expect(english?.native == "English")
        #expect(english?.feature.contains("Feature") == true)
        #expect(english?.scenario.contains("Scenario") == true)
        #expect(english?.given.contains("Given ") == true)
        #expect(english?.when.contains("When ") == true)
        #expect(english?.then.contains("Then ") == true)
        #expect(english?.and.contains("And ") == true)
        #expect(english?.but.contains("But ") == true)
    }

    @Test("French language is loaded")
    func frenchLoaded() {
        let french = LanguageRegistry.language(for: "fr")
        #expect(french != nil)
        #expect(french?.name == "French")
        #expect(french?.feature.contains("Fonctionnalité") == true)
    }

    @Test("Japanese language is loaded")
    func japaneseLoaded() {
        let japanese = LanguageRegistry.language(for: "ja")
        #expect(japanese != nil)
        #expect(japanese?.name == "Japanese")
        #expect(japanese?.feature.contains("フィーチャ") == true)
    }

    @Test("German language is loaded")
    func germanLoaded() {
        let german = LanguageRegistry.language(for: "de")
        #expect(german != nil)
        #expect(german?.name == "German")
        #expect(german?.feature.contains("Funktionalität") == true)
    }

    @Test("Chinese Simplified language is loaded")
    func chineseLoaded() {
        let chinese = LanguageRegistry.language(for: "zh-CN")
        #expect(chinese != nil)
        #expect(chinese?.name == "Chinese simplified")
    }

    @Test("Unknown language returns nil")
    func unknownLanguage() {
        let unknown = LanguageRegistry.language(for: "xx-unknown")
        #expect(unknown == nil)
    }

    @Test("Default language is English")
    func defaultLanguage() {
        let def = LanguageRegistry.defaultLanguage
        #expect(def.code == "en")
        #expect(def.name == "English")
    }

    @Test("Supported language codes includes en and fr")
    func supportedCodes() {
        let codes = LanguageRegistry.supportedLanguageCodes
        #expect(codes.contains("en"))
        #expect(codes.contains("fr"))
        #expect(codes.contains("ja"))
        #expect(codes.count > 50)  // Should have 70+ languages
    }

    @Test("All step keywords include wildcard")
    func wildcardInStepKeywords() {
        let english = LanguageRegistry.language(for: "en")
        #expect(english?.given.contains("* ") == true)
        #expect(english?.when.contains("* ") == true)
        #expect(english?.then.contains("* ") == true)
        #expect(english?.and.contains("* ") == true)
        #expect(english?.but.contains("* ") == true)
    }

    @Test("English scenario outline keywords")
    func scenarioOutlineKeywords() {
        let english = LanguageRegistry.language(for: "en")
        #expect(english?.scenarioOutline.contains("Scenario Outline") == true)
        #expect(english?.scenarioOutline.contains("Scenario Template") == true)
    }

    @Test("English examples keywords")
    func examplesKeywords() {
        let english = LanguageRegistry.language(for: "en")
        #expect(english?.examples.contains("Examples") == true)
        #expect(english?.examples.contains("Scenarios") == true)
    }

    // MARK: - GherkinLanguage Properties

    @Test("allStepKeywords combines all step keyword arrays")
    func allStepKeywords() throws {
        let lang = try #require(LanguageRegistry.language(for: "en"))
        let allSteps = lang.allStepKeywords
        #expect(allSteps.contains("Given "))
        #expect(allSteps.contains("When "))
        #expect(allSteps.contains("Then "))
        #expect(allSteps.contains("And "))
        #expect(allSteps.contains("But "))
        #expect(allSteps.contains("* "))
    }

    @Test("allStructuralKeywords combines structural keyword arrays")
    func allStructuralKeywords() throws {
        let lang = try #require(LanguageRegistry.language(for: "en"))
        let all = lang.allStructuralKeywords
        #expect(all.contains("Feature"))
        #expect(all.contains("Rule"))
        #expect(all.contains("Background"))
        #expect(all.contains("Scenario"))
        #expect(all.contains("Scenario Outline"))
        #expect(all.contains("Examples"))
    }

    @Test("GherkinLanguage is equatable and hashable")
    func languageEquatable() throws {
        let en1 = try #require(LanguageRegistry.language(for: "en"))
        let en2 = try #require(LanguageRegistry.language(for: "en"))
        let fr = try #require(LanguageRegistry.language(for: "fr"))
        #expect(en1 == en2)
        #expect(en1 != fr)

        let set: Set<GherkinLanguage> = [en1, en2, fr]
        #expect(set.count == 2)
    }

    @Test("language has correct native name")
    func nativeName() throws {
        let fr = try #require(LanguageRegistry.language(for: "fr"))
        #expect(fr.native == "français")

        let ja = try #require(LanguageRegistry.language(for: "ja"))
        #expect(ja.native == "日本語")
    }

    @Test("language background keywords loaded")
    func backgroundKeywords() throws {
        let en = try #require(LanguageRegistry.language(for: "en"))
        #expect(en.background.contains("Background"))

        let fr = try #require(LanguageRegistry.language(for: "fr"))
        #expect(fr.background.contains("Contexte"))
    }

    @Test("language rule keywords loaded")
    func ruleKeywords() throws {
        let en = try #require(LanguageRegistry.language(for: "en"))
        #expect(en.rule.contains("Rule"))
    }

    @Test("all supported languages have non-empty feature keyword")
    func allLanguagesHaveFeature() {
        let codes = LanguageRegistry.supportedLanguageCodes
        for code in codes {
            let lang = LanguageRegistry.language(for: code)
            #expect(lang != nil, "Language '\(code)' should be loaded")
            #expect(lang?.feature.isEmpty == false, "Language '\(code)' should have feature keywords")
        }
    }

    @Test("languages dictionary is populated with 70+ entries")
    func languagesCount() {
        let count = LanguageRegistry.languages.count
        #expect(count >= 70)
    }
}

@Suite("LanguageDetector Tests")
struct LanguageDetectorTests {

    @Test("Detects English by default")
    func detectsEnglishDefault() {
        let lang = LanguageDetector.detectLanguage(from: "Feature: Test")
        #expect(lang.code == "en")
    }

    @Test("Detects language header")
    func detectsLanguageHeader() {
        let source = """
            # language: fr
            Fonctionnalité: Test
            """
        let code = LanguageDetector.detectLanguageCode(from: source)
        #expect(code == "fr")
    }

    @Test("Detects language header with extra whitespace")
    func detectsWithWhitespace() {
        let source = "  #   language:   ja  \n"
        let code = LanguageDetector.detectLanguageCode(from: source)
        #expect(code == "ja")
    }

    @Test("Returns nil when no language header")
    func noLanguageHeader() {
        let code = LanguageDetector.detectLanguageCode(from: "Feature: Test")
        #expect(code == nil)
    }

    @Test("Skips empty lines before language header")
    func skipsEmptyLines() {
        let source = "\n\n# language: de\nFunktionalität: Test"
        let code = LanguageDetector.detectLanguageCode(from: source)
        #expect(code == "de")
    }

    @Test("Skips regular comments before language header")
    func skipsRegularComments() {
        let source = """
            # Some comment
            # language: fr
            """
        let code = LanguageDetector.detectLanguageCode(from: source)
        #expect(code == "fr")
    }

    @Test("Stops at first non-comment, non-empty line")
    func stopsAtContent() {
        let source = """
            Feature: Test
            # language: fr
            """
        let code = LanguageDetector.detectLanguageCode(from: source)
        #expect(code == nil)
    }

    @Test("Detects language and returns GherkinLanguage")
    func detectsFullLanguage() {
        let source = "# language: fr\nFonctionnalité: Test"
        let lang = LanguageDetector.detectLanguage(from: source)
        #expect(lang.code == "fr")
        #expect(lang.name == "French")
    }

    @Test("Unknown language code falls back to English")
    func unknownCodeFallback() {
        let source = "# language: zz-unknown\nFeature: Test"
        let lang = LanguageDetector.detectLanguage(from: source)
        #expect(lang.code == "en")
    }

    @Test("Empty source returns nil code")
    func emptySource() {
        let code = LanguageDetector.detectLanguageCode(from: "")
        #expect(code == nil)
    }
}
