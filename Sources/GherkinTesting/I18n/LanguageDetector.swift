// LanguageDetector.swift
// GherkinTesting
//
// Copyright © 2026 Atelier Socle. MIT License.

/// Detects the Gherkin language from a `# language:` header comment.
///
/// The language header must appear on the first non-empty line of a `.feature` file.
/// If no header is found, the default language (English) is used.
///
/// ```gherkin
/// # language: fr
/// Fonctionnalité: Authentification
/// ```
public enum LanguageDetector: Sendable {

    /// Detects the language code from the source text.
    ///
    /// Scans for a `# language: <code>` directive on the first non-empty line.
    /// The directive is case-insensitive for the keyword but the language code
    /// is matched as-is against the registry.
    ///
    /// - Parameter source: The full Gherkin source text.
    /// - Returns: The detected language code (e.g. `"fr"`), or `nil` if no header is found.
    public static func detectLanguageCode(from source: String) -> String? {
        for line in source.split(separator: "\n", omittingEmptySubsequences: false) {
            let trimmed = line.trimmingCharacters(in: .whitespaces)

            // Skip empty lines
            if trimmed.isEmpty {
                continue
            }

            // Check for language directive
            if trimmed.hasPrefix("#") {
                let afterHash = trimmed.dropFirst().trimmingCharacters(in: .whitespaces)
                if afterHash.lowercased().hasPrefix("language:") {
                    let codeStart = afterHash.index(afterHash.startIndex, offsetBy: 9) // "language:".count
                    let code = afterHash[codeStart...].trimmingCharacters(in: .whitespaces)
                    return code.isEmpty ? nil : code
                }
                // It's a comment but not a language directive — continue looking
                continue
            }

            // First non-empty, non-comment line found — no language header
            return nil
        }

        return nil
    }

    /// Detects the ``GherkinLanguage`` from the source text.
    ///
    /// - Parameter source: The full Gherkin source text.
    /// - Returns: The detected ``GherkinLanguage``, or the default (English) if not found or unknown.
    public static func detectLanguage(from source: String) -> GherkinLanguage {
        guard let code = detectLanguageCode(from: source) else {
            return LanguageRegistry.defaultLanguage
        }
        return LanguageRegistry.language(for: code) ?? LanguageRegistry.defaultLanguage
    }
}
