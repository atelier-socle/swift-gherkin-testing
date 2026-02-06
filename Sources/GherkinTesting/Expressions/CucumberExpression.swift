// CucumberExpression.swift
// GherkinTesting
//
// Copyright © 2026 Atelier Socle. MIT License.

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

    /// Creates and compiles a Cucumber expression.
    ///
    /// Validates the expression at creation time by compiling the regex pattern.
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

        // Validate that the pattern compiles — fail fast at creation time
        _ = try Regex(compiledPattern)
    }

    /// Matches a step text against this expression.
    ///
    /// For each capture group, applies the parameter type's string transformer
    /// to produce ``CucumberMatch/rawArguments`` and the typed transformer to
    /// produce ``CucumberMatch/typedArguments``.
    ///
    /// - Parameter text: The step text to match.
    /// - Returns: A ``CucumberMatch`` if the text matches, or `nil` if it doesn't.
    /// - Throws: If regex matching or argument transformation fails.
    public func match(_ text: String) throws -> CucumberMatch? {
        let regex = try Regex(pattern)
        guard let result = try regex.wholeMatch(in: text) else {
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
