// StepSuggestion.swift
// GherkinTesting
//
// Copyright © 2026 Atelier Socle. MIT License.

/// A code suggestion generated when a step is undefined.
///
/// When a pickle step has no matching step definition, `StepSuggestion`
/// generates a copy-pasteable Swift code skeleton that the user can
/// add to their feature struct.
///
/// The analyzer detects common patterns in the step text:
/// - Numbers (e.g. `42`, `-100`) → `{int}`
/// - Floats (e.g. `3.14`, `-2.5`) → `{float}`
/// - Quoted strings (e.g. `"hello"`, `'world'`) → `{string}`
///
/// ```swift
/// let suggestion = StepSuggestion.suggest(stepText: "the user has 42 items")
/// print(suggestion.suggestedExpression)
/// // "the user has {int} items"
/// print(suggestion.suggestedSignature)
/// // @Given("the user has {int} items")
/// // func theUserHasIntItems() async throws {
/// //     throw PendingStepError()
/// // }
/// ```
public struct StepSuggestion: Sendable, Equatable {
    /// The original step text that was undefined.
    public let stepText: String

    /// The suggested Cucumber expression with detected parameter types.
    public let suggestedExpression: String

    /// The full suggested code snippet including annotation and function body.
    public let suggestedSignature: String

    /// The keyword type of the step, if known.
    public let keywordType: StepKeywordType?

    /// Creates a new step suggestion.
    ///
    /// - Parameters:
    ///   - stepText: The original step text.
    ///   - suggestedExpression: The suggested Cucumber expression.
    ///   - suggestedSignature: The full code snippet.
    ///   - keywordType: The keyword type, or `nil` if unknown.
    public init(
        stepText: String,
        suggestedExpression: String,
        suggestedSignature: String,
        keywordType: StepKeywordType?
    ) {
        self.stepText = stepText
        self.suggestedExpression = suggestedExpression
        self.suggestedSignature = suggestedSignature
        self.keywordType = keywordType
    }

    /// Generates a step suggestion by analyzing the step text for common patterns.
    ///
    /// Detects numbers, floats, and quoted strings in the text and replaces
    /// them with appropriate Cucumber expression parameter types.
    ///
    /// - Parameters:
    ///   - stepText: The undefined step text to analyze.
    ///   - keywordType: The keyword type for the annotation. Defaults to `nil` (→ `@Given`).
    /// - Returns: A suggestion with expression and code skeleton.
    public static func suggest(
        stepText: String,
        keywordType: StepKeywordType? = nil
    ) -> StepSuggestion {
        let expression = analyzePattern(stepText)
        let funcName = generateFunctionName(from: expression)
        let keyword = macroKeyword(for: keywordType)
        let escapedExpression = expression.replacing("\\", with: "\\\\").replacing("\"", with: "\\\"")
        let signature = """
        @\(keyword)("\(escapedExpression)")
        func \(funcName)() async throws {
            throw PendingStepError()
        }
        """
        return StepSuggestion(
            stepText: stepText,
            suggestedExpression: expression,
            suggestedSignature: signature,
            keywordType: keywordType
        )
    }

    // MARK: - Pattern Analysis

    /// Analyzes step text and replaces detected literal values with Cucumber expression placeholders.
    ///
    /// Detection order: quoted strings first, then floats, then integers.
    ///
    /// - Parameter text: The step text to analyze.
    /// - Returns: A Cucumber expression string with placeholders.
    static func analyzePattern(_ text: String) -> String {
        var result: [Character] = []
        let chars = Array(text)
        var i = 0

        while i < chars.count {
            let ch = chars[i]

            // Quoted strings: "..." or '...'
            if ch == "\"" || ch == "'" {
                let quote = ch
                var j = i + 1
                while j < chars.count && chars[j] != quote {
                    j += 1
                }
                if j < chars.count {
                    // Found closing quote
                    j += 1
                    result.append(contentsOf: "{string}")
                    i = j
                    continue
                }
                // Unclosed quote — treat as literal
            }

            // Numbers: optional minus, then digits, optionally followed by .digits (float)
            if isDigit(ch) || (ch == "-" && i + 1 < chars.count && isDigit(chars[i + 1])) {
                var j = i
                if chars[j] == "-" { j += 1 }
                while j < chars.count && isDigit(chars[j]) { j += 1 }

                // Check for float: .digits
                if j < chars.count && chars[j] == "." && j + 1 < chars.count && isDigit(chars[j + 1]) {
                    j += 1
                    while j < chars.count && isDigit(chars[j]) { j += 1 }
                    result.append(contentsOf: "{float}")
                } else {
                    result.append(contentsOf: "{int}")
                }
                i = j
                continue
            }

            result.append(ch)
            i += 1
        }

        return String(result)
    }

    /// Generates a camelCase function name from a Cucumber expression.
    ///
    /// Extracts words and parameter type names, joins them in camelCase.
    /// For example: `"the user has {int} items"` → `"theUserHasIntItems"`.
    ///
    /// - Parameter expression: The Cucumber expression.
    /// - Returns: A camelCase function name.
    static func generateFunctionName(from expression: String) -> String {
        var words: [String] = []
        var currentWord: [Character] = []

        for ch in expression {
            if ch == "{" || ch == "}" {
                if !currentWord.isEmpty {
                    words.append(String(currentWord))
                    currentWord = []
                }
            } else if ch.isLetter || ch.isNumber {
                currentWord.append(ch)
            } else {
                if !currentWord.isEmpty {
                    words.append(String(currentWord))
                    currentWord = []
                }
            }
        }
        if !currentWord.isEmpty {
            words.append(String(currentWord))
        }

        guard !words.isEmpty else { return "pendingStep" }

        var result = words[0].lowercased()
        for word in words.dropFirst() {
            if let first = word.first {
                result += String(first).uppercased() + String(word.dropFirst()).lowercased()
            }
        }

        return result
    }

    /// Returns the macro keyword name for a given step keyword type.
    ///
    /// - Parameter keywordType: The step keyword type, or `nil`.
    /// - Returns: The macro annotation name (e.g. `"Given"`, `"When"`, `"Then"`).
    static func macroKeyword(for keywordType: StepKeywordType?) -> String {
        switch keywordType {
        case .context: return "Given"
        case .action: return "When"
        case .outcome: return "Then"
        default: return "Given"
        }
    }

    /// Checks whether a character is an ASCII digit (0-9).
    private static func isDigit(_ ch: Character) -> Bool {
        ch >= "0" && ch <= "9"
    }
}
