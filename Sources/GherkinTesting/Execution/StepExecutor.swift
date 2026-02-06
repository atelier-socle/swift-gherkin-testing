// StepExecutor.swift
// GherkinTesting
//
// Copyright © 2026 Atelier Socle. MIT License.

/// Matches pickle steps against registered step definitions and executes them.
///
/// The `StepExecutor` holds a list of step definitions and provides methods
/// to match a step's text against those definitions and execute the matched
/// handler. The matching strategy (until Cucumber Expressions in Phase 5) is:
///
/// 1. Exact string match (fastest)
/// 2. Regex match with capture group extraction (compiled on demand)
/// 3. If 0 matches → ``StepMatchError/undefined(stepText:)``
/// 4. If 2+ matches → ``StepMatchError/ambiguous(stepText:matchDescriptions:)``
///
/// The generic parameter `F` is the concrete feature type whose step
/// definitions are registered in this executor.
///
/// ```swift
/// let executor = StepExecutor<LoginFeature>(definitions: myDefinitions)
/// let match = try executor.match(step)
/// try await executor.execute(step, on: &feature)
/// ```
public struct StepExecutor<F: GherkinFeature>: Sendable {
    /// The registered step definitions to match against.
    public let definitions: [StepDefinition<F>]

    /// Creates a new step executor.
    ///
    /// - Parameter definitions: The step definitions to match against.
    public init(definitions: [StepDefinition<F>]) {
        self.definitions = definitions
    }

    /// Matches a pickle step against the registered definitions.
    ///
    /// Tries exact string matching first, then regex matching. Returns the
    /// single match found, or throws if zero or multiple definitions match.
    /// Regex patterns are compiled from their source string on each match call.
    ///
    /// - Parameter step: The pickle step to match.
    /// - Returns: A ``StepMatch`` with the matched definition and captured arguments.
    /// - Throws: ``StepMatchError/undefined(stepText:)`` if no definition matches,
    ///   ``StepMatchError/ambiguous(stepText:matchDescriptions:)`` if multiple match.
    public func match(_ step: PickleStep) throws -> StepMatch<F> {
        var matches: [(definition: StepDefinition<F>, arguments: [String])] = []

        for definition in definitions {
            switch definition.pattern {
            case .exact(let pattern):
                if step.text == pattern {
                    matches.append((definition, []))
                }
            case .regex(let source):
                if let regex = try? Regex(source),
                   let result = try? regex.wholeMatch(in: step.text) {
                    let captures = Self.extractCaptures(from: result)
                    matches.append((definition, captures))
                }
            }
        }

        switch matches.count {
        case 0:
            throw StepMatchError.undefined(stepText: step.text)
        case 1:
            let (definition, arguments) = matches[0]
            return StepMatch(
                stepDefinition: definition,
                arguments: arguments,
                matchLocation: definition.sourceLocation
            )
        default:
            let descriptions = matches.map(\.definition.patternDescription)
            throw StepMatchError.ambiguous(stepText: step.text, matchDescriptions: descriptions)
        }
    }

    /// Matches and executes a pickle step against the registered definitions.
    ///
    /// Calls ``match(_:)`` to find the matching definition, then invokes
    /// the definition's handler with the captured arguments.
    ///
    /// - Parameters:
    ///   - step: The pickle step to match and execute.
    ///   - feature: A mutable reference to the feature instance.
    /// - Throws: ``StepMatchError`` if the step cannot be matched,
    ///   or any error thrown by the step handler during execution.
    public func execute(_ step: PickleStep, on feature: inout F) async throws {
        let stepMatch = try match(step)
        try await stepMatch.stepDefinition.handler(&feature, stepMatch.arguments)
    }

    /// Extracts capture group strings from a regex match output.
    ///
    /// - Parameter match: The regex match result.
    /// - Returns: An array of captured group strings (excluding the full match).
    static func extractCaptures(from match: Regex<AnyRegexOutput>.Match) -> [String] {
        var captures: [String] = []
        let output = match.output
        // Skip index 0 (full match); capture groups start at index 1
        for index in 1..<output.count {
            if let substring = output[index].substring {
                captures.append(String(substring))
            }
        }
        return captures
    }
}
