// ExpressionParser.swift
// GherkinTesting
//
// Copyright © 2026 Atelier Socle. MIT License.

import Foundation

/// An error that occurs while parsing a Cucumber expression.
public enum ExpressionError: Error, Sendable, Equatable, LocalizedError {
    /// The expression contains an unterminated parameter placeholder.
    case unterminatedParameter(String)

    /// The expression contains an unterminated optional group.
    case unterminatedOptional(String)

    /// The expression references an unknown parameter type.
    ///
    /// - Parameter name: The unknown parameter type name.
    case unknownParameterType(String)

    /// The expression is empty.
    case emptyExpression

    /// An alternation has an empty alternative.
    case emptyAlternative(String)

    /// An alternation contains a parameter — not allowed by spec.
    case parameterInAlternation(String)

    /// Optional text contains a parameter — not allowed by spec.
    case parameterInOptional(String)

    /// A localized description of the expression error.
    public var errorDescription: String? {
        switch self {
        case .unterminatedParameter(let expr):
            return "Unterminated parameter in expression: '\(expr)'"
        case .unterminatedOptional(let expr):
            return "Unterminated optional group in expression: '\(expr)'"
        case .unknownParameterType(let typeName):
            return "Unknown parameter type '{\(typeName)}' in expression."
        case .emptyExpression:
            return "Cucumber expression must not be empty."
        case .emptyAlternative(let expr):
            return "Empty alternative in alternation: '\(expr)'"
        case .parameterInAlternation(let expr):
            return "Parameters are not allowed in alternation: '\(expr)'"
        case .parameterInOptional(let expr):
            return "Parameters are not allowed in optional text: '\(expr)'"
        }
    }
}

/// A token produced by the Cucumber expression tokenizer.
public enum ExpressionToken: Equatable, Sendable {
    /// Literal text to match exactly.
    case text(String)

    /// A parameter placeholder like `{int}`, `{string}`, or `{}`.
    case parameter(String)

    /// Optional text like `(text)` which may or may not be present.
    case optional(String)

    /// Alternation like `color/colour` offering multiple choices.
    case alternation([String])
}

/// Parses a Cucumber expression string into tokens and compiles to a regex pattern.
///
/// The parser handles:
/// - Parameter placeholders: `{int}`, `{float}`, `{string}`, `{word}`, `{}`, `{custom}`
/// - Optional text: `(text)` → `(?:text)?`
/// - Alternation: `word1/word2` → `(?:word1|word2)`
/// - Escaping: `\{`, `\(`, `\/`, `\\` for literal characters
///
/// ```swift
/// let parser = ExpressionParser(registry: ParameterTypeRegistry())
/// let (pattern, typeNames) = try parser.compile("I have {int} cucumber(s)")
/// // pattern = "^I have (-?\\d+) cucumber(?:s)?$"
/// // typeNames = ["int"]
/// ```
public struct ExpressionParser: Sendable {
    /// The parameter type registry for resolving parameter names.
    public let registry: ParameterTypeRegistry

    /// Creates a new expression parser.
    ///
    /// - Parameter registry: The parameter type registry.
    public init(registry: ParameterTypeRegistry) {
        self.registry = registry
    }

    // MARK: - Tokenization

    /// Tokenizes a Cucumber expression into a list of tokens.
    ///
    /// Handles alternation `/` directly in the main loop to avoid
    /// re-splitting after escape resolution. Escaped characters
    /// (`\{`, `\}`, `\(`, `\)`, `\/`, `\\`) are resolved during tokenization.
    ///
    /// - Parameter expression: The Cucumber expression string.
    /// - Returns: An array of expression tokens.
    /// - Throws: ``ExpressionError`` if the expression is malformed.
    public func tokenize(_ expression: String) throws -> [ExpressionToken] {
        var tokens: [ExpressionToken] = []
        let chars = Array(expression)
        var index = 0
        var textBuffer = ""
        // Tracks alternation state: nil means no alternation in progress
        var alternationParts: [String]? = nil

        while index < chars.count {
            let char = chars[index]

            // Handle escape sequences: \{ \} \( \) \/ \\
            if char == "\\" && index + 1 < chars.count {
                let next = chars[index + 1]
                if next == "{" || next == "}" || next == "(" || next == ")"
                    || next == "/" || next == "\\" {
                    textBuffer.append(next)
                    index += 2
                    continue
                }
            }

            switch char {
            case "{":
                // Flush text buffer (with alternation if active)
                flushTextBuffer(&textBuffer, alternation: &alternationParts, into: &tokens)

                // Find closing brace
                guard let closeIndex = findClosing(chars, from: index, open: "{", close: "}") else {
                    throw ExpressionError.unterminatedParameter(expression)
                }
                let paramName = String(chars[(index + 1)..<closeIndex])
                tokens.append(.parameter(paramName))
                index = closeIndex + 1

            case "(":
                // Flush text buffer
                flushTextBuffer(&textBuffer, alternation: &alternationParts, into: &tokens)

                // Find closing paren
                guard let closeIndex = findClosing(chars, from: index, open: "(", close: ")") else {
                    throw ExpressionError.unterminatedOptional(expression)
                }
                let optionalText = String(chars[(index + 1)..<closeIndex])

                // Validate: no parameters inside optional
                if optionalText.contains("{") {
                    throw ExpressionError.parameterInOptional(expression)
                }

                tokens.append(.optional(optionalText))
                index = closeIndex + 1

            case "/":
                // Start or extend alternation
                if alternationParts == nil {
                    alternationParts = [textBuffer]
                } else {
                    alternationParts?.append(textBuffer)
                }
                textBuffer = ""
                index += 1

            default:
                textBuffer.append(char)
                index += 1
            }
        }

        // Flush remaining text
        flushTextBuffer(&textBuffer, alternation: &alternationParts, into: &tokens)

        return tokens
    }

    /// Flushes the text buffer and any pending alternation into the token list.
    ///
    /// When alternation is active, the buffered text segments between `/` are
    /// emitted as an `.alternation` token. Leading text before the first `/`
    /// that shares a word boundary is split so only the word-level alternatives
    /// are in the alternation, and surrounding text is emitted as `.text`.
    ///
    /// - Parameters:
    ///   - buffer: The current text buffer.
    ///   - alternation: The alternation parts collected so far, or `nil`.
    ///   - tokens: The token list to append to.
    private func flushTextBuffer(
        _ buffer: inout String,
        alternation: inout [String]?,
        into tokens: inout [ExpressionToken]
    ) {
        if var parts = alternation {
            parts.append(buffer)

            // Split shared prefix/suffix from alternation parts so that
            // "I eat/drink a " becomes text("I ") + alternation(["eat","drink"]) + text(" a ")
            let (prefix, alts, suffix) = extractAlternationBoundaries(parts)
            if !prefix.isEmpty {
                tokens.append(.text(prefix))
            }
            tokens.append(.alternation(alts))
            if !suffix.isEmpty {
                tokens.append(.text(suffix))
            }

            alternation = nil
        } else if !buffer.isEmpty {
            tokens.append(.text(buffer))
        }
        buffer = ""
    }

    /// Extracts the common prefix and suffix from alternation parts.
    ///
    /// Given `["I eat", "drink a "]`, finds:
    /// - The first part's text up to the last space: `"I "` (common prefix)
    /// - The last part's text after the first space: `" a "` (common suffix)
    /// - The alternation words: `["eat", "drink"]`
    ///
    /// - Parameter parts: The raw alternation segments.
    /// - Returns: A tuple of (prefix, alternatives, suffix).
    private func extractAlternationBoundaries(
        _ parts: [String]
    ) -> (prefix: String, alternatives: [String], suffix: String) {
        guard parts.count >= 2 else {
            return ("", parts, "")
        }

        let first = parts[0]
        let last = parts[parts.count - 1]

        // Find prefix: everything before the last space in the first part
        let prefix: String
        let firstAlternative: String
        if let lastSpace = first.lastIndex(of: " ") {
            let splitIndex = first.index(after: lastSpace)
            prefix = String(first[first.startIndex..<splitIndex])
            firstAlternative = String(first[splitIndex...])
        } else {
            prefix = ""
            firstAlternative = first
        }

        // Find suffix: everything after the first space in the last part
        let suffix: String
        let lastAlternative: String
        if let firstSpace = last.firstIndex(of: " ") {
            lastAlternative = String(last[last.startIndex..<firstSpace])
            suffix = String(last[firstSpace...])
        } else {
            lastAlternative = last
            suffix = ""
        }

        // Build the alternatives array
        var alternatives = [firstAlternative]
        for i in 1..<(parts.count - 1) {
            alternatives.append(parts[i])
        }
        alternatives.append(lastAlternative)

        return (prefix, alternatives, suffix)
    }

    // MARK: - Compilation

    /// Compiles a Cucumber expression into a regex pattern string and parameter type names.
    ///
    /// - Parameter expression: The Cucumber expression string.
    /// - Returns: A tuple of (regexPattern, parameterTypeNames).
    /// - Throws: ``ExpressionError`` if the expression is malformed or references unknown types.
    public func compile(_ expression: String) throws -> (pattern: String, typeNames: [String]) {
        let tokens = try tokenize(expression)
        var regexParts: [String] = []
        var typeNames: [String] = []

        for token in tokens {
            switch token {
            case .text(let text):
                regexParts.append(escapeRegex(text))

            case .parameter(let name):
                guard let paramType = registry.lookup(name) else {
                    throw ExpressionError.unknownParameterType(name)
                }
                let regexAlternatives = paramType.regexps
                if regexAlternatives.count == 1 {
                    regexParts.append("(\(regexAlternatives[0]))")
                } else {
                    let joined = regexAlternatives.joined(separator: "|")
                    regexParts.append("(\(joined))")
                }
                typeNames.append(name)

            case .optional(let text):
                let escaped = escapeRegex(text)
                regexParts.append("(?:\(escaped))?")

            case .alternation(let alternatives):
                let escaped = alternatives.map { escapeRegex($0) }
                regexParts.append("(?:\(escaped.joined(separator: "|")))")
            }
        }

        let pattern = "^\(regexParts.joined())$"
        return (pattern, typeNames)
    }

    // MARK: - Private Helpers

    /// Finds the index of a closing delimiter, respecting nesting.
    private func findClosing(
        _ chars: [Character],
        from startIndex: Int,
        open: Character,
        close: Character
    ) -> Int? {
        var depth = 0
        var index = startIndex

        while index < chars.count {
            let char = chars[index]

            // Handle escapes
            if char == "\\" && index + 1 < chars.count {
                index += 2
                continue
            }

            if char == open {
                depth += 1
            } else if char == close {
                depth -= 1
                if depth == 0 {
                    return index
                }
            }
            index += 1
        }
        return nil
    }

    /// Escapes special regex metacharacters in literal text.
    private func escapeRegex(_ text: String) -> String {
        let metacharacters: [Character] = [
            ".", "*", "+", "?", "^", "$", "|",
            "[", "]", "\\", "(", ")", "{", "}"
        ]
        var result = ""
        result.reserveCapacity(text.count)
        for char in text {
            if metacharacters.contains(char) {
                result.append("\\")
            }
            result.append(char)
        }
        return result
    }
}
