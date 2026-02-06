// LanguageRegistry.swift
// GherkinTesting
//
// Copyright © 2026 Atelier Socle. MIT License.

import Foundation

/// A registry of all supported Gherkin languages.
///
/// Loads the official `gherkin-languages.json` once on first access and provides
/// O(1) lookup by language code. Supports all 70+ languages from the Cucumber project.
///
/// ```swift
/// let french = LanguageRegistry.language(for: "fr")
/// print(french?.feature) // ["Fonctionnalité"]
/// ```
public enum LanguageRegistry: Sendable {

    /// All loaded languages keyed by language code.
    ///
    /// Loaded lazily on first access from the bundled `gherkin-languages.json` resource.
    public static let languages: [String: GherkinLanguage] = {
        loadLanguages()
    }()

    /// Returns the language definition for the given language code.
    ///
    /// - Parameter code: The ISO language code (e.g. `"en"`, `"fr"`, `"ja"`).
    /// - Returns: The ``GherkinLanguage`` for the code, or `nil` if not found.
    public static func language(for code: String) -> GherkinLanguage? {
        languages[code]
    }

    /// The default language used when no `# language:` header is present.
    public static let defaultLanguage: GherkinLanguage = {
        guard let english = languages["en"] else {
            return makeDefaultEnglish()
        }
        return english
    }()

    /// Creates the hardcoded English fallback language.
    ///
    /// Used when `gherkin-languages.json` cannot be loaded or does not contain `"en"`.
    /// This should never happen in normal usage since the JSON always includes English.
    ///
    /// - Returns: A ``GherkinLanguage`` for English with all standard keywords.
    static func makeDefaultEnglish() -> GherkinLanguage {
        GherkinLanguage(
            code: "en",
            name: "English",
            native: "English",
            feature: ["Feature", "Business Need", "Ability"],
            rule: ["Rule"],
            background: ["Background"],
            scenario: ["Example", "Scenario"],
            scenarioOutline: ["Scenario Outline", "Scenario Template"],
            examples: ["Examples", "Scenarios"],
            given: ["* ", "Given "],
            when: ["* ", "When "],
            then: ["* ", "Then "],
            and: ["* ", "And "],
            but: ["* ", "But "]
        )
    }

    /// All supported language codes.
    ///
    /// - Returns: An array of all language codes (e.g. `["af", "am", "an", ...]`).
    public static var supportedLanguageCodes: [String] {
        Array(languages.keys).sorted()
    }

    // MARK: - Internal Loading

    private static func loadLanguages() -> [String: GherkinLanguage] {
        let url = Bundle.module.url(forResource: "gherkin-languages", withExtension: "json")
        return loadLanguages(from: url)
    }

    /// Loads languages from a URL, returning empty on any failure.
    ///
    /// This is the testable entry point for the loading pipeline. Accepts an optional
    /// URL so callers (and tests) can simulate missing/corrupt resource scenarios.
    ///
    /// - Parameter url: The URL to read JSON from. Returns `[:]` when `nil`.
    /// - Returns: A dictionary of language code to ``GherkinLanguage``.
    static func loadLanguages(from url: URL?) -> [String: GherkinLanguage] {
        guard let url else { return [:] }

        guard let data = try? Data(contentsOf: url) else {
            return [:]
        }

        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return [:]
        }

        return parseLanguages(from: json)
    }

    /// Parses language entries from a raw JSON dictionary.
    ///
    /// Each top-level key is a language code (e.g. `"en"`, `"fr"`) mapping to a dictionary
    /// of keyword arrays. Missing or mistyped fields fall back to the code string or empty arrays.
    ///
    /// - Parameter json: The raw JSON dictionary from `gherkin-languages.json`.
    /// - Returns: A dictionary of language code to ``GherkinLanguage``.
    static func parseLanguages(from json: [String: Any]) -> [String: GherkinLanguage] {
        var result: [String: GherkinLanguage] = [:]
        result.reserveCapacity(json.count)

        for (code, value) in json {
            guard let langDict = value as? [String: Any] else { continue }

            let language = GherkinLanguage(
                code: code,
                name: langDict["name"] as? String ?? code,
                native: langDict["native"] as? String ?? code,
                feature: langDict["feature"] as? [String] ?? [],
                rule: langDict["rule"] as? [String] ?? [],
                background: langDict["background"] as? [String] ?? [],
                scenario: langDict["scenario"] as? [String] ?? [],
                scenarioOutline: langDict["scenarioOutline"] as? [String] ?? [],
                examples: langDict["examples"] as? [String] ?? [],
                given: langDict["given"] as? [String] ?? [],
                when: langDict["when"] as? [String] ?? [],
                then: langDict["then"] as? [String] ?? [],
                and: langDict["and"] as? [String] ?? [],
                but: langDict["but"] as? [String] ?? []
            )
            result[code] = language
        }

        return result
    }
}
