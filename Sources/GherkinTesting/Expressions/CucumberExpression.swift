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

/// The result of successfully matching a step text against a ``CucumberExpression``.
///
/// Contains both the raw captured strings and the typed values produced by
/// each parameter type's transformer. Use ``rawArguments`` for string-based
/// processing and ``typedArguments`` for typed values (e.g. `Int`, `Double`).
///
/// ```swift
/// let expression = try CucumberExpression("I have {int} cucumber(s)", registry: registry)
/// if let match = try expression.match("I have 5 cucumbers") {
///     print(match.rawArguments)    // ["5"]
///     print(match.typedArguments)  // [5]  (as Int)
///     print(match.paramTypeNames)  // ["int"]
/// }
/// ```
public struct CucumberMatch: Sendable {
    /// The raw captured argument strings from the regex match.
    ///
    /// These are the string values after applying the parameter type's
    /// string transformer (e.g. `{string}` strips surrounding quotes).
    public let rawArguments: [String]

    /// The typed argument values produced by each parameter type's typed transformer.
    ///
    /// For example, `{int}` produces an `Int`, `{float}` produces a `Double`,
    /// and `{string}` produces a `String` with quotes stripped.
    ///
    /// ```swift
    /// let match = try expr.match("I have -42 cucumbers")
    /// let count = match.typedArguments[0] as! Int  // -42
    /// ```
    public let typedArguments: [any Sendable]

    /// The parameter type names corresponding to each capture group.
    ///
    /// For example, `["int", "string"]` for an expression `"I have {int} {string}"`.
    public let paramTypeNames: [String]

    /// Creates a new Cucumber match result.
    ///
    /// - Parameters:
    ///   - rawArguments: The raw captured strings.
    ///   - typedArguments: The typed values from parameter type transformers.
    ///   - paramTypeNames: The parameter type names for each capture.
    public init(rawArguments: [String], typedArguments: [any Sendable], paramTypeNames: [String]) {
        self.rawArguments = rawArguments
        self.typedArguments = typedArguments
        self.paramTypeNames = paramTypeNames
    }
}

extension CucumberMatch: Equatable {
    /// Compares two matches by their raw arguments and parameter type names.
    ///
    /// Typed arguments are excluded from equality since `any Sendable` is not `Equatable`.
    public static func == (lhs: CucumberMatch, rhs: CucumberMatch) -> Bool {
        lhs.rawArguments == rhs.rawArguments && lhs.paramTypeNames == rhs.paramTypeNames
    }
}

/// A Sendable wrapper for `Regex<AnyRegexOutput>`.
///
/// `Regex` is immutable after creation and safe to share across threads, but
/// `Regex<Output>` does not yet conform to `Sendable` in the standard library.
/// This wrapper bridges the gap for use in `Sendable` types.
///
/// - Note: Remove this wrapper when `Regex` gains `Sendable` conformance
///   in a future Swift release (tracked by Swift evolution).
package struct SendableRegex: @unchecked Sendable {
    /// The wrapped regex value.
    package let regex: Regex<AnyRegexOutput>

    /// Creates a wrapper by compiling a pattern string.
    ///
    /// - Parameter pattern: The regex pattern to compile.
    /// - Throws: If the pattern is invalid.
    package init(compiling pattern: String) throws {
        self.regex = try Regex(pattern)
    }
}

/// A compiled Cucumber expression that can match step text and extract typed arguments.
///
/// Parses a Cucumber expression string (e.g. `"I have {int} cucumber(s)"`) into
/// a compiled regex pattern, then provides a `match()` method to test step text
/// against the pattern and extract captured arguments.
///
/// Supports:
/// - Parameter placeholders: `{int}`, `{float}`, `{string}`, `{word}`, `{}`, `{custom}`
/// - Optional text: `(text)` makes text optional
/// - Alternation: `word1/word2` matches either word
/// - Escaping: `\{`, `\(`, `\/`, `\\` for literals
///
/// ```swift
/// let registry = ParameterTypeRegistry()
/// let expr = try CucumberExpression("I have {int} cucumber(s)", registry: registry)
/// let match = try expr.match("I have 5 cucumbers")
/// // match?.rawArguments == ["5"]
/// ```
public struct CucumberExpression: Sendable {
    /// The original expression string.
    public let source: String

    /// The compiled regex pattern string.
    public let pattern: String

    /// The parameter type names for each capture group, in order.
    public let paramTypeNames: [String]

    /// The parameter type registry used for argument transformation.
    public let registry: ParameterTypeRegistry

    /// The pre-compiled regex for matching, avoiding re-compilation on every match.
    private let compiledRegex: SendableRegex

    /// Creates and compiles a Cucumber expression.
    ///
    /// The regex is compiled once at creation time and cached for all subsequent matches.
    ///
    /// - Parameters:
    ///   - source: The Cucumber expression string.
    ///   - registry: The parameter type registry. Defaults to a new registry with built-in types.
    /// - Throws: ``ExpressionError`` if the expression is malformed.
    public init(_ source: String, registry: ParameterTypeRegistry = ParameterTypeRegistry()) throws {
        self.source = source
        self.registry = registry

        let parser = ExpressionParser(registry: registry)
        let (compiledPattern, typeNames) = try parser.compile(source)
        self.pattern = compiledPattern
        self.paramTypeNames = typeNames

        // Compile once, reuse on every match
        self.compiledRegex = try SendableRegex(compiling: compiledPattern)
    }

    /// Matches a step text against this expression.
    ///
    /// Uses the pre-compiled regex for fast matching. For each capture group,
    /// applies the parameter type's string transformer to produce
    /// ``CucumberMatch/rawArguments`` and the typed transformer to produce
    /// ``CucumberMatch/typedArguments``.
    ///
    /// - Parameter text: The step text to match.
    /// - Returns: A ``CucumberMatch`` if the text matches, or `nil` if it doesn't.
    /// - Throws: If regex matching or argument transformation fails.
    public func match(_ text: String) throws -> CucumberMatch? {
        guard let result = try compiledRegex.regex.wholeMatch(in: text) else {
            return nil
        }

        var rawArguments: [String] = []
        var typedArguments: [any Sendable] = []
        let output = result.output

        // Skip index 0 (full match); capture groups start at index 1
        for index in 1..<output.count {
            if let substring = output[index].substring {
                let raw = String(substring)
                let paramName = index - 1 < paramTypeNames.count ? paramTypeNames[index - 1] : ""
                if let paramType = registry.lookup(paramName) {
                    let transformed = try paramType.transformer(raw)
                    rawArguments.append(transformed)
                    let typed = try paramType.typedTransformer(raw)
                    typedArguments.append(typed)
                } else {
                    rawArguments.append(raw)
                    typedArguments.append(raw)
                }
            }
        }

        return CucumberMatch(
            rawArguments: rawArguments,
            typedArguments: typedArguments,
            paramTypeNames: paramTypeNames
        )
    }

    /// The number of capture groups (parameter placeholders) in this expression.
    public var parameterCount: Int {
        paramTypeNames.count
    }
}
