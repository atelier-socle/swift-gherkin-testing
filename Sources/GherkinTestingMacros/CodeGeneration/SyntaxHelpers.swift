// SyntaxHelpers.swift
// GherkinTestingMacros
//
// Copyright © 2026 Atelier Socle. MIT License.

import SwiftSyntax
import SwiftSyntaxMacros

/// Utility functions for working with SwiftSyntax nodes in macro implementations.
///
/// All helpers are pure Swift — no Foundation dependency (not available in macro plugins).
enum SyntaxHelpers {

    // MARK: - String Utilities (no Foundation)

    /// Finds the first occurrence of a substring within a string.
    ///
    /// - Parameters:
    ///   - string: The string to search in.
    ///   - target: The substring to find.
    ///   - startIndex: The index to start searching from.
    /// - Returns: The range of the first match, or `nil`.
    static func findSubstring(
        in string: String,
        _ target: String,
        from startIndex: String.Index? = nil
    ) -> Range<String.Index>? {
        let searchStart = startIndex ?? string.startIndex
        guard !target.isEmpty, searchStart < string.endIndex else { return nil }

        let targetChars = Array(target)
        var index = searchStart

        while index < string.endIndex {
            var matchIndex = index
            var targetIdx = 0
            var matched = true

            while targetIdx < targetChars.count {
                guard matchIndex < string.endIndex, string[matchIndex] == targetChars[targetIdx] else {
                    matched = false
                    break
                }
                matchIndex = string.index(after: matchIndex)
                targetIdx += 1
            }

            if matched {
                return index..<matchIndex
            }
            index = string.index(after: index)
        }

        return nil
    }

    /// Checks if a string contains a given substring.
    ///
    /// - Parameters:
    ///   - string: The string to search in.
    ///   - target: The substring to find.
    /// - Returns: `true` if the substring is found.
    static func containsSubstring(_ string: String, _ target: String) -> Bool {
        findSubstring(in: string, target) != nil
    }

    /// Replaces all occurrences of a substring within a string.
    ///
    /// - Parameters:
    ///   - string: The original string.
    ///   - target: The substring to find.
    ///   - replacement: The replacement string.
    /// - Returns: The string with all occurrences replaced.
    static func replaceAll(in string: String, _ target: String, with replacement: String) -> String {
        guard !target.isEmpty else { return string }
        var result = ""
        var searchStart = string.startIndex

        while let range = findSubstring(in: string, target, from: searchStart) {
            result += string[searchStart..<range.lowerBound]
            result += replacement
            searchStart = range.upperBound
        }

        result += string[searchStart...]
        return result
    }

    /// Trims leading and trailing whitespace/newline characters from a string.
    ///
    /// - Parameter string: The string to trim.
    /// - Returns: The trimmed string.
    static func trimWhitespace(_ string: some StringProtocol) -> String {
        var start = string.startIndex
        var end = string.endIndex

        while start < end && (string[start] == " " || string[start] == "\t"
                              || string[start] == "\n" || string[start] == "\r") {
            start = string.index(after: start)
        }

        while end > start {
            let prev = string.index(before: end)
            if string[prev] == " " || string[prev] == "\t"
                || string[prev] == "\n" || string[prev] == "\r" {
                end = prev
            } else {
                break
            }
        }

        return String(string[start..<end])
    }

    /// Escapes a string for embedding inside a Swift string literal.
    ///
    /// Handles backslashes, double quotes, newlines, tabs, and carriage returns.
    ///
    /// - Parameter string: The input string.
    /// - Returns: The escaped string (without surrounding quotes).
    static func escapeForStringLiteral(_ string: String) -> String {
        var result = ""
        result.reserveCapacity(string.count)
        for char in string {
            switch char {
            case "\\": result += "\\\\"
            case "\"": result += "\\\""
            case "\n": result += "\\n"
            case "\r": result += "\\r"
            case "\t": result += "\\t"
            default: result.append(char)
            }
        }
        return result
    }

    // MARK: - SwiftSyntax Extraction

    /// Extracts a plain string from a `StringLiteralExprSyntax`.
    ///
    /// Returns the concatenated text of all string segments, or `nil` if the
    /// literal contains interpolations or is otherwise non-trivial.
    ///
    /// - Parameter expr: A string literal expression syntax node.
    /// - Returns: The literal string value, or `nil` if it cannot be statically extracted.
    static func extractStringLiteral(from expr: StringLiteralExprSyntax) -> String? {
        var result = ""
        for segment in expr.segments {
            switch segment {
            case .stringSegment(let seg):
                result += seg.content.text
            case .expressionSegment:
                return nil
            }
        }
        return result
    }

    /// Sanitizes a string for use as a Swift identifier.
    ///
    /// Replaces non-alphanumeric characters with underscores, collapses
    /// consecutive underscores, and removes leading/trailing underscores.
    /// If the result starts with a digit, prepends an underscore.
    ///
    /// - Parameter string: The input string to sanitize.
    /// - Returns: A valid Swift identifier derived from the input.
    static func sanitizeIdentifier(_ string: String) -> String {
        var result = ""
        for char in string {
            if char.isLetter || char.isNumber || char == "_" {
                result.append(char)
            } else {
                result.append("_")
            }
        }

        // Collapse consecutive underscores
        while containsSubstring(result, "__") {
            result = replaceAll(in: result, "__", with: "_")
        }

        // Trim leading/trailing underscores
        while result.hasPrefix("_") { result.removeFirst() }
        while result.hasSuffix("_") { result.removeLast() }

        // Prefix with underscore if starts with digit
        if let first = result.first, first.isNumber {
            result = "_" + result
        }

        if result.isEmpty {
            result = "unnamed"
        }

        return result
    }

    // MARK: - Cucumber Expressions

    /// Converts a Cucumber expression to a regex pattern string.
    ///
    /// Handles the standard Cucumber expression placeholders:
    /// - `{int}` → `(-?\d+)`
    /// - `{float}` → `(-?\d+\.\d+)`
    /// - `{string}` → `"([^"]*)"`
    /// - `{word}` → `(\S+)`
    /// - `{}` → `(.*)`
    ///
    /// If the expression contains no placeholders, returns `nil` (use exact match).
    ///
    /// - Parameter expression: A Cucumber expression string.
    /// - Returns: A regex pattern string, or `nil` if no placeholders are found.
    static func cucumberExpressionToRegex(_ expression: String) -> String? {
        let placeholders: [(String, String)] = [
            ("{int}", #"(-?\d+)"#),
            ("{float}", #"(-?\d+\.\d+)"#),
            ("{string}", #""([^"]*)""#),
            ("{word}", #"(\S+)"#),
            ("{}", #"(.*)"#),
        ]

        var result = expression
        var hasPlaceholder = false

        for (placeholder, regex) in placeholders {
            if containsSubstring(result, placeholder) {
                hasPlaceholder = true
                result = replaceAll(in: result, placeholder, with: regex)
            }
        }

        guard hasPlaceholder else { return nil }
        return "^\(result)$"
    }

    /// Counts the number of capture groups in a Cucumber expression.
    ///
    /// - Parameter expression: A Cucumber expression string.
    /// - Returns: The number of capture groups (placeholders).
    static func captureGroupCount(in expression: String) -> Int {
        let placeholders = ["{int}", "{float}", "{string}", "{word}", "{}"]
        var count = 0
        for placeholder in placeholders {
            var searchStart = expression.startIndex
            while let range = findSubstring(in: expression, placeholder, from: searchStart) {
                count += 1
                searchStart = range.upperBound
            }
        }
        return count
    }

    // MARK: - Function Declaration Inspection

    /// Extracts the function name from a `FunctionDeclSyntax`.
    ///
    /// - Parameter decl: A function declaration.
    /// - Returns: The function's base name as a string.
    static func functionName(from decl: FunctionDeclSyntax) -> String {
        decl.name.text
    }

    /// Extracts parameter names from a function declaration.
    ///
    /// - Parameter decl: A function declaration.
    /// - Returns: An array of external parameter names (or `_` if no external name).
    static func parameterNames(from decl: FunctionDeclSyntax) -> [String] {
        decl.signature.parameterClause.parameters.map { param in
            param.firstName.text
        }
    }

    /// Counts the parameters in a function declaration.
    ///
    /// - Parameter decl: A function declaration.
    /// - Returns: The number of parameters.
    static func parameterCount(from decl: FunctionDeclSyntax) -> Int {
        decl.signature.parameterClause.parameters.count
    }

    /// Checks if a function declaration is marked `async`.
    ///
    /// - Parameter decl: A function declaration.
    /// - Returns: `true` if the function is async.
    static func isAsync(_ decl: FunctionDeclSyntax) -> Bool {
        decl.signature.effectSpecifiers?.asyncSpecifier != nil
    }

    /// Checks if a function declaration is marked `throws`.
    ///
    /// - Parameter decl: A function declaration.
    /// - Returns: `true` if the function throws.
    static func isThrows(_ decl: FunctionDeclSyntax) -> Bool {
        decl.signature.effectSpecifiers?.throwsClause != nil
    }

    /// Checks if a function declaration has the `mutating` modifier.
    ///
    /// - Parameter decl: A function declaration.
    /// - Returns: `true` if the function is mutating.
    static func isMutating(_ decl: FunctionDeclSyntax) -> Bool {
        decl.modifiers.contains { $0.name.text == "mutating" }
    }

    /// Checks if a function declaration has the `static` modifier.
    ///
    /// - Parameter decl: A function declaration.
    /// - Returns: `true` if the function is static.
    static func isStatic(_ decl: FunctionDeclSyntax) -> Bool {
        decl.modifiers.contains { $0.name.text == "static" }
    }

    // MARK: - Gherkin Source Scanning

    /// Extracts scenario names from inline Gherkin source by simple line scanning.
    ///
    /// Looks for lines starting with "Scenario:" or "Scenario Outline:" (trimmed)
    /// and extracts the name portion. This is a lightweight approach that avoids
    /// needing the full parser at compile time.
    ///
    /// - Parameter source: The Gherkin source text.
    /// - Returns: An array of scenario names found.
    static func extractScenarioNames(from source: String) -> [String] {
        let prefixes = ["Scenario Outline:", "Scenario Template:", "Scenario:", "Example:"]
        var names: [String] = []

        for line in source.split(separator: "\n", omittingEmptySubsequences: false) {
            let trimmed = trimWhitespace(line)
            for prefix in prefixes {
                if trimmed.hasPrefix(prefix) {
                    let name = trimWhitespace(String(trimmed.dropFirst(prefix.count)))
                    if !name.isEmpty {
                        names.append(name)
                    }
                    break
                }
            }
        }

        return names
    }
}
