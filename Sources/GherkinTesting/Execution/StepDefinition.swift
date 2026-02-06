// StepDefinition.swift
// GherkinTesting
//
// Copyright © 2026 Atelier Socle. MIT License.

/// The pattern used to match a step definition against a pickle step's text.
///
/// Step patterns can be either exact string matches (fastest) or regular
/// expression patterns with capture groups for argument extraction.
/// The regex is compiled on demand during matching in ``StepExecutor``.
public enum StepPattern: Sendable, Equatable, Hashable {
    /// An exact string match. The pickle step text must equal this string exactly.
    ///
    /// - Parameter pattern: The exact text to match.
    case exact(String)

    /// A regular expression pattern source string.
    ///
    /// The regex is compiled from this source at match time by ``StepExecutor``.
    /// - Parameter source: The regular expression pattern string.
    case regex(String)

    /// A human-readable description of this pattern for diagnostics.
    public var description: String {
        switch self {
        case .exact(let string):
            return string
        case .regex(let source):
            return "/\(source)/"
        }
    }
}

/// A registered step definition that maps a pattern to an executable handler.
///
/// Step definitions are created by the `@Given`, `@When`, `@Then` macros (Phase 4)
/// or registered manually. Each definition associates a text pattern with a handler
/// closure that executes when a matching pickle step is found.
///
/// The generic parameter `F` is the concrete feature type whose state the
/// handler can mutate during execution.
///
/// ```swift
/// let definition = StepDefinition<LoginFeature>(
///     keywordType: .context,
///     pattern: .exact("the user is logged in"),
///     sourceLocation: Location(line: 10, column: 5),
///     handler: { feature, args in
///         feature.loggedIn = true
///     }
/// )
/// ```
public struct StepDefinition<F: GherkinFeature>: Sendable {
    /// The semantic keyword type this definition matches, or `nil` for any type.
    public let keywordType: StepKeywordType?

    /// The pattern used to match step text.
    public let pattern: StepPattern

    /// The source code location where this definition was declared.
    public let sourceLocation: Location

    /// The handler closure executed when a step matches this definition.
    ///
    /// - Parameters:
    ///   - feature: A mutable reference to the feature instance for state mutation.
    ///   - arguments: The captured arguments from pattern matching (strings).
    public let handler: @Sendable (inout F, [String]) async throws -> Void

    /// Creates a new step definition.
    ///
    /// - Parameters:
    ///   - keywordType: The semantic keyword type, or `nil` to match any.
    ///   - pattern: The pattern for matching step text.
    ///   - sourceLocation: The location in source code where this was defined.
    ///   - handler: The closure to execute when matched.
    public init(
        keywordType: StepKeywordType? = nil,
        pattern: StepPattern,
        sourceLocation: Location,
        handler: @escaping @Sendable (inout F, [String]) async throws -> Void
    ) {
        self.keywordType = keywordType
        self.pattern = pattern
        self.sourceLocation = sourceLocation
        self.handler = handler
    }

    /// A human-readable description of this definition's pattern.
    public var patternDescription: String {
        pattern.description
    }
}
