// RegexStepMatcher.swift
// GherkinTesting
//
// Copyright © 2026 Atelier Socle. MIT License.

/// A pre-compiled pattern for fast step matching without re-compilation.
private enum CompiledPattern<F: GherkinFeature>: Sendable {
    /// Exact string match — compare directly.
    case exact(String)

    /// Pre-compiled Cucumber expression with cached regex.
    case cucumberExpression(CucumberExpression)

    /// Pre-compiled regex from a raw pattern string.
    case regex(SendableRegex)
}

/// Unified step matching engine with priority-based resolution.
///
/// Matches a step's text against a list of step definitions using three
/// strategies in priority order:
///
/// 1. **Exact string match** — fastest, no argument extraction
/// 2. **Cucumber Expression match** — typed parameters via ``CucumberExpression``
/// 3. **Regex match** — raw regex with capture groups
///
/// All patterns are pre-compiled at init time. No regex compilation occurs
/// during `match()` calls, ensuring consistent sub-microsecond per-step matching.
///
/// If multiple definitions match, returns ``StepMatchError/ambiguous(stepText:matchDescriptions:)``.
/// If none match, returns ``StepMatchError/undefined(stepText:)``.
///
/// ```swift
/// let matcher = RegexStepMatcher<MyFeature>(
///     definitions: definitions,
///     registry: ParameterTypeRegistry()
/// )
/// let match = try matcher.match(step)
/// ```
public struct RegexStepMatcher<F: GherkinFeature>: Sendable {
    /// The registered step definitions to match against.
    public let definitions: [StepDefinition<F>]

    /// The parameter type registry for Cucumber Expression matching.
    public let registry: ParameterTypeRegistry

    /// Pre-compiled patterns parallel to `definitions`, built once at init.
    private let compiledPatterns: [CompiledPattern<F>]

    /// Creates a new step matcher.
    ///
    /// All Cucumber expressions and regex patterns are compiled once at creation
    /// time. If a pattern fails to compile, it is stored as a non-matching sentinel.
    ///
    /// - Parameters:
    ///   - definitions: The step definitions to match against.
    ///   - registry: The parameter type registry. Defaults to built-in types.
    public init(
        definitions: [StepDefinition<F>],
        registry: ParameterTypeRegistry = ParameterTypeRegistry()
    ) {
        self.definitions = definitions
        self.registry = registry

        // Pre-compile all patterns once
        self.compiledPatterns = definitions.map { definition in
            switch definition.pattern {
            case .exact(let pattern):
                return .exact(pattern)
            case .cucumberExpression(let source):
                if let expr = try? CucumberExpression(source, registry: registry) {
                    return .cucumberExpression(expr)
                }
                // If compilation fails, store as exact (won't match anything realistically)
                return .exact("")
            case .regex(let source):
                if let compiled = try? SendableRegex(compiling: source) {
                    return .regex(compiled)
                }
                return .exact("")
            }
        }
    }

    /// Matches a pickle step against the registered definitions.
    ///
    /// Uses pre-compiled patterns for fast matching. No regex compilation
    /// occurs during this call.
    ///
    /// - Parameter step: The pickle step to match.
    /// - Returns: A ``StepMatch`` with the matched definition and captured arguments.
    /// - Throws: ``StepMatchError/undefined(stepText:)`` if no definition matches,
    ///   ``StepMatchError/ambiguous(stepText:matchDescriptions:)`` if multiple match.
    public func match(_ step: PickleStep) throws -> StepMatch<F> {
        var matches: [(definition: StepDefinition<F>, arguments: [String], priority: Int)] = []

        for (index, compiled) in compiledPatterns.enumerated() {
            let definition = definitions[index]

            switch compiled {
            case .exact(let pattern):
                if step.text == pattern {
                    matches.append((definition, [], 0))
                }

            case .cucumberExpression(let expression):
                if let cucumberMatch = try expression.match(step.text) {
                    matches.append((definition, cucumberMatch.rawArguments, 1))
                }

            case .regex(let compiledRegex):
                if let result = try? compiledRegex.regex.wholeMatch(in: step.text) {
                    let captures = extractCaptures(from: result)
                    matches.append((definition, captures, 2))
                }
            }
        }

        switch matches.count {
        case 0:
            throw StepMatchError.undefined(stepText: step.text)
        case 1:
            let (definition, arguments, _) = matches[0]
            return StepMatch(
                stepDefinition: definition,
                arguments: arguments,
                matchLocation: definition.sourceLocation
            )
        default:
            // If we have matches at different priority levels, take the highest (lowest number)
            let bestPriority = matches.min(by: { $0.priority < $1.priority })?.priority ?? 0
            let bestMatches = matches.filter { $0.priority == bestPriority }

            if bestMatches.count == 1 {
                let (definition, arguments, _) = bestMatches[0]
                return StepMatch(
                    stepDefinition: definition,
                    arguments: arguments,
                    matchLocation: definition.sourceLocation
                )
            }

            let descriptions = bestMatches.map { match in
                let loc = match.definition.sourceLocation
                return "\(match.definition.patternDescription) (line \(loc.line))"
            }
            throw StepMatchError.ambiguous(stepText: step.text, matchDescriptions: descriptions)
        }
    }

    /// Extracts capture group strings from a regex match output.
    ///
    /// - Parameter match: The regex match result.
    /// - Returns: An array of captured group strings (excluding the full match).
    private func extractCaptures(from match: Regex<AnyRegexOutput>.Match) -> [String] {
        var captures: [String] = []
        let output = match.output
        for index in 1..<output.count {
            if let substring = output[index].substring {
                captures.append(String(substring))
            }
        }
        return captures
    }
}
