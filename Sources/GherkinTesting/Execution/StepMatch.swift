// StepMatch.swift
// GherkinTesting
//
// Copyright © 2026 Atelier Socle. MIT License.

/// The result of successfully matching a pickle step against a step definition.
///
/// A `StepMatch` is produced by ``StepExecutor/match(_:)`` and contains the
/// matched definition, the arguments captured from the step text during
/// pattern matching, and the source location of the definition.
///
/// The generic parameter `F` is the concrete feature type, matching the
/// ``StepDefinition`` that produced this match.
///
/// ```swift
/// let executor = StepExecutor<LoginFeature>(definitions: definitions)
/// let match = try executor.match(step)
/// print("Matched: \(match.stepDefinition.patternDescription)")
/// print("Arguments: \(match.arguments)")
/// ```
public struct StepMatch<F: GherkinFeature>: Sendable {
    /// The step definition that matched.
    public let stepDefinition: StepDefinition<F>

    /// The arguments captured from the step text by the pattern.
    ///
    /// For exact matches, this array is empty. For regex matches,
    /// it contains the strings captured by each capture group in order.
    public let arguments: [String]

    /// The source location of the matched step definition.
    public let matchLocation: Location

    /// Creates a new step match result.
    ///
    /// - Parameters:
    ///   - stepDefinition: The matched step definition.
    ///   - arguments: The captured argument strings.
    ///   - matchLocation: The source location of the definition.
    public init(stepDefinition: StepDefinition<F>, arguments: [String], matchLocation: Location) {
        self.stepDefinition = stepDefinition
        self.arguments = arguments
        self.matchLocation = matchLocation
    }
}
