// SPDX-License-Identifier: Apache-2.0
//
// Copyright 2026 Atelier Socle SAS
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

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
    private static let whitespaceChars: Set<Character> = [" ", "\t", "\n", "\r"]

    static func trimWhitespace(_ string: some StringProtocol) -> String {
        var start = string.startIndex
        var end = string.endIndex

        while start < end && whitespaceChars.contains(string[start]) {
            start = string.index(after: start)
        }

        while end > start {
            let prev = string.index(before: end)
            if whitespaceChars.contains(string[prev]) {
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

    /// The detected type of a step expression.
    ///
    /// Used by ``StepRegistryCodeGen`` to generate the correct ``StepPattern`` case.
    enum ExpressionKind {
        /// An exact string match (no placeholders, no regex metacharacters).
        case exact

        /// A Cucumber expression with parameter placeholders, optional text, or alternation.
        case cucumberExpression

        /// A raw regular expression pattern.
        case regex
    }

    /// Detects whether an expression is exact, a Cucumber expression, or a regex.
    ///
    /// Detection rules:
    /// - If pattern starts with `^` or contains `\d`, `[`, `]` → regex
    /// - If pattern contains `{...}`, `(...)`, or unescaped `/` → Cucumber expression
    /// - Otherwise → exact string match
    ///
    /// - Parameter expression: The expression string.
    /// - Returns: The detected expression kind.
    static func detectExpressionKind(_ expression: String) -> ExpressionKind {
        // Regex indicators: starts with ^, ends with $, contains \d, [, ]
        if expression.hasPrefix("^") || expression.hasSuffix("$") {
            return .regex
        }
        let regexIndicators = [#"\d"#, #"\s"#, #"\w"#, #"\b"#, "[", "]"]
        for indicator in regexIndicators where containsSubstring(expression, indicator) {
            return .regex
        }

        // Cucumber expression indicators: {param}, (optional), alternation /
        if containsSubstring(expression, "{") && containsSubstring(expression, "}") {
            return .cucumberExpression
        }
        if containsCucumberOptional(expression) {
            return .cucumberExpression
        }
        if containsUnescapedSlash(expression) {
            return .cucumberExpression
        }

        return .exact
    }

    /// Checks if the expression contains unescaped parentheses (Cucumber optional text).
    private static func containsCucumberOptional(_ expression: String) -> Bool {
        let chars = Array(expression)
        for i in 0..<chars.count where chars[i] == "(" {
            // Check it's not escaped
            if i == 0 || chars[i - 1] != "\\" {
                return true
            }
        }
        return false
    }

    /// Checks if the expression contains unescaped `/` (Cucumber alternation).
    private static func containsUnescapedSlash(_ expression: String) -> Bool {
        let chars = Array(expression)
        for i in 0..<chars.count where chars[i] == "/" {
            if i == 0 || chars[i - 1] != "\\" {
                return true
            }
        }
        return false
    }

    /// Counts the number of capture groups in a Cucumber expression.
    ///
    /// Counts `{...}` parameter placeholders (including `{}`).
    ///
    /// - Parameter expression: A Cucumber expression string.
    /// - Returns: The number of capture groups.
    static func captureGroupCount(in expression: String) -> Int {
        let kind = detectExpressionKind(expression)
        switch kind {
        case .exact:
            return 0
        case .cucumberExpression:
            return countCucumberParameters(in: expression)
        case .regex:
            return countRegexCaptureGroups(in: expression)
        }
    }

    /// Counts `{...}` parameter placeholders in a Cucumber expression.
    private static func countCucumberParameters(in expression: String) -> Int {
        var count = 0
        let chars = Array(expression)
        var i = 0
        while i < chars.count {
            if chars[i] == "\\" && i + 1 < chars.count {
                i += 2
                continue
            }
            if chars[i] == "{" {
                // Find matching }
                var j = i + 1
                while j < chars.count && chars[j] != "}" {
                    j += 1
                }
                if j < chars.count {
                    count += 1
                    i = j + 1
                } else {
                    i += 1
                }
            } else {
                i += 1
            }
        }
        return count
    }

    /// Counts capture groups `(...)` in a regex pattern, excluding non-capturing `(?:...)`.
    private static func countRegexCaptureGroups(in pattern: String) -> Int {
        var count = 0
        let chars = Array(pattern)
        var i = 0
        while i < chars.count {
            if chars[i] == "\\" && i + 1 < chars.count {
                i += 2
                continue
            }
            if chars[i] == "(" {
                // Check for non-capturing group (?:
                if i + 2 < chars.count && chars[i + 1] == "?" && chars[i + 2] == ":" {
                    i += 1
                } else {
                    count += 1
                    i += 1
                }
            } else {
                i += 1
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

    /// Extracts the type name of the last parameter in a function declaration.
    ///
    /// Returns the trimmed type name string (e.g. `"DataTable"`, `"String"`),
    /// or `nil` if there are no parameters or no type annotation.
    ///
    /// - Parameter decl: A function declaration.
    /// - Returns: The type name of the last parameter, or `nil`.
    static func lastParameterTypeName(from decl: FunctionDeclSyntax) -> String? {
        guard let lastParam = decl.signature.parameterClause.parameters.last else { return nil }
        return trimWhitespace(lastParam.type.trimmedDescription)
    }

    // MARK: - Gherkin Source Scanning

    /// Extracts scenario names from inline Gherkin source by simple line scanning.
    ///
    /// Uses ``ScenarioKeywords/allPrefixes`` which contains all scenario and
    /// scenario outline keywords from all 80 Gherkin languages. Outline/template
    /// variants are checked first to avoid prefix conflicts with basic scenario keywords.
    ///
    /// - Parameter source: The Gherkin source text.
    /// - Returns: An array of scenario names found.
    static func extractScenarioNames(from source: String) -> [String] {
        var names: [String] = []

        // Normalize escaped newlines from string literal syntax (where \n is two chars)
        let normalized = replaceAll(in: source, "\\n", with: "\n")

        for line in normalized.split(separator: "\n", omittingEmptySubsequences: false) {
            let trimmed = trimWhitespace(line)
            for prefix in ScenarioKeywords.allPrefixes where trimmed.hasPrefix(prefix) {
                let name = trimWhitespace(String(trimmed.dropFirst(prefix.count)))
                if !name.isEmpty {
                    names.append(name)
                }
                break
            }
        }

        return names
    }
}
