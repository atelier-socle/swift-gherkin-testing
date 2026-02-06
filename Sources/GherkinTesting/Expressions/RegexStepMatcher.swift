// RegexStepMatcher.swift
// GherkinTesting
//
// Copyright © 2026 Atelier Socle. MIT License.

/// Unified step matching engine with priority-based resolution.
///
/// Matches a step's text against a list of step definitions using three
/// strategies in priority order:
///
/// 1. **Exact string match** — fastest, no argument extraction
/// 2. **Cucumber Expression match** — typed parameters via ``CucumberExpression``
/// 3. **Regex match** — raw regex with capture groups
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

    /// Creates a new step matcher.
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
    }

    /// Matches a pickle step against the registered definitions.
    ///
    /// Tries all definitions and collects matches. Each match is assigned a
    /// priority based on its pattern type (exact > cucumber > regex).
    ///
    /// - Parameter step: The pickle step to match.
    /// - Returns: A ``StepMatch`` with the matched definition and captured arguments.
    /// - Throws: ``StepMatchError/undefined(stepText:)`` if no definition matches,
    ///   ``StepMatchError/ambiguous(stepText:matchDescriptions:)`` if multiple match.
    public func match(_ step: PickleStep) throws -> StepMatch<F> {
        var matches: [(definition: StepDefinition<F>, arguments: [String], priority: Int)] = []

        for definition in definitions {
            switch definition.pattern {
            case .exact(let pattern):
                if step.text == pattern {
                    matches.append((definition, [], 0))
                }

            case .cucumberExpression(let source):
                if let cucumberMatch = try matchCucumberExpression(source, against: step.text) {
                    matches.append((definition, cucumberMatch.rawArguments, 1))
                }

            case .regex(let source):
                if let regex = try? Regex(source),
                   let result = try? regex.wholeMatch(in: step.text) {
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

            let descriptions = bestMatches.map(\.definition.patternDescription)
            throw StepMatchError.ambiguous(stepText: step.text, matchDescriptions: descriptions)
        }
    }

    /// Attempts to match a Cucumber expression source against step text.
    ///
    /// - Parameters:
    ///   - source: The Cucumber expression source string.
    ///   - text: The step text to match against.
    /// - Returns: A ``CucumberMatch`` if matched, or `nil`.
    /// - Throws: If expression compilation or matching fails.
    private func matchCucumberExpression(_ source: String, against text: String) throws -> CucumberMatch? {
        let expression = try CucumberExpression(source, registry: registry)
        return try expression.match(text)
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
