// LanguageRegistryTests.swift
// GherkinTestingTests
//
// Copyright © 2026 Atelier Socle. MIT License.

import Foundation
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

    // MARK: - parseLanguages fallback coverage

    @Test("parseLanguages with missing name field falls back to code")
    func parseLanguagesMissingName() {
        let json: [String: Any] = [
            "xx": ["native": "Test", "feature": ["F"]] as [String: Any]
        ]
        let result = LanguageRegistry.parseLanguages(from: json)
        let lang = result["xx"]
        #expect(lang?.name == "xx")
    }

    @Test("parseLanguages with missing native field falls back to code")
    func parseLanguagesMissingNative() {
        let json: [String: Any] = [
            "yy": ["name": "Test"] as [String: Any]
        ]
        let result = LanguageRegistry.parseLanguages(from: json)
        let lang = result["yy"]
        #expect(lang?.native == "yy")
    }

    @Test("parseLanguages with missing keyword arrays falls back to empty")
    func parseLanguagesMissingKeywords() {
        let json: [String: Any] = [
            "zz": ["name": "Test", "native": "Test"] as [String: Any]
        ]
        let result = LanguageRegistry.parseLanguages(from: json)
        let lang = result["zz"]
        #expect(lang?.feature == [])
        #expect(lang?.rule == [])
        #expect(lang?.background == [])
        #expect(lang?.scenario == [])
        #expect(lang?.scenarioOutline == [])
        #expect(lang?.examples == [])
        #expect(lang?.given == [])
        #expect(lang?.when == [])
        #expect(lang?.then == [])
        #expect(lang?.and == [])
        #expect(lang?.but == [])
    }

    @Test("parseLanguages skips non-dictionary values")
    func parseLanguagesSkipsInvalid() {
        let json: [String: Any] = [
            "good": ["name": "Good", "native": "Good", "feature": ["F"]] as [String: Any],
            "bad": "not a dictionary",
            "also_bad": 42
        ]
        let result = LanguageRegistry.parseLanguages(from: json)
        #expect(result.count == 1)
        #expect(result["good"] != nil)
        #expect(result["bad"] == nil)
        #expect(result["also_bad"] == nil)
    }

    @Test("parseLanguages with empty JSON returns empty")
    func parseLanguagesEmpty() {
        let result = LanguageRegistry.parseLanguages(from: [:])
        #expect(result.isEmpty)
    }

    @Test("parseLanguages with wrongly typed fields falls back")
    func parseLanguagesWrongTypes() {
        let json: [String: Any] = [
            "tt": [
                "name": 42,
                "native": ["array"],
                "feature": "not an array",
                "given": 99
            ] as [String: Any]
        ]
        let result = LanguageRegistry.parseLanguages(from: json)
        let lang = result["tt"]
        #expect(lang?.name == "tt")
        #expect(lang?.native == "tt")
        #expect(lang?.feature == [])
        #expect(lang?.given == [])
    }

    // MARK: - loadLanguages(from:) coverage

    @Test("loadLanguages from nil URL returns empty")
    func loadLanguagesNilURL() {
        let result = LanguageRegistry.loadLanguages(from: nil)
        #expect(result.isEmpty)
    }

    @Test("loadLanguages from non-existent URL returns empty")
    func loadLanguagesNonExistentURL() {
        let url = URL(fileURLWithPath: "/nonexistent/path/to/languages.json")
        let result = LanguageRegistry.loadLanguages(from: url)
        #expect(result.isEmpty)
    }

    @Test("loadLanguages from non-JSON file returns empty")
    func loadLanguagesInvalidJSON() throws {
        let tmpDir = FileManager.default.temporaryDirectory
        let tmpFile = tmpDir.appendingPathComponent("not-json-\(UUID().uuidString).txt")
        try "this is not json".write(to: tmpFile, atomically: true, encoding: .utf8)
        defer { try? FileManager.default.removeItem(at: tmpFile) }

        let result = LanguageRegistry.loadLanguages(from: tmpFile)
        #expect(result.isEmpty)
    }

    @Test("loadLanguages from valid JSON URL returns languages")
    func loadLanguagesValidJSON() throws {
        let tmpDir = FileManager.default.temporaryDirectory
        let tmpFile = tmpDir.appendingPathComponent("test-langs-\(UUID().uuidString).json")
        let jsonStr = """
            {"test": {"name": "Test", "native": "Test", "feature": ["Feature"]}}
            """
        try jsonStr.write(to: tmpFile, atomically: true, encoding: .utf8)
        defer { try? FileManager.default.removeItem(at: tmpFile) }

        let result = LanguageRegistry.loadLanguages(from: tmpFile)
        #expect(result.count == 1)
        #expect(result["test"]?.name == "Test")
    }

    // MARK: - makeDefaultEnglish coverage

    @Test("makeDefaultEnglish returns correct fallback language")
    func makeDefaultEnglishFallback() {
        let english = LanguageRegistry.makeDefaultEnglish()
        #expect(english.code == "en")
        #expect(english.name == "English")
        #expect(english.native == "English")
        #expect(english.feature.contains("Feature"))
        #expect(english.feature.contains("Business Need"))
        #expect(english.feature.contains("Ability"))
        #expect(english.rule.contains("Rule"))
        #expect(english.background.contains("Background"))
        #expect(english.scenario.contains("Scenario"))
        #expect(english.scenario.contains("Example"))
        #expect(english.scenarioOutline.contains("Scenario Outline"))
        #expect(english.scenarioOutline.contains("Scenario Template"))
        #expect(english.examples.contains("Examples"))
        #expect(english.examples.contains("Scenarios"))
        #expect(english.given.contains("Given "))
        #expect(english.given.contains("* "))
        #expect(english.when.contains("When "))
        #expect(english.then.contains("Then "))
        #expect(english.and.contains("And "))
        #expect(english.but.contains("But "))
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
