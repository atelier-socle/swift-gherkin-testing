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

/// Matches pickle steps against registered step definitions and executes them.
///
/// The `StepExecutor` holds a list of step definitions and a parameter type
/// registry, and delegates matching to ``RegexStepMatcher``. The matching
/// strategy uses priority-based resolution:
///
/// 1. Exact string match (fastest)
/// 2. Cucumber Expression match with typed parameters
/// 3. Regex match with capture group extraction
/// 4. If 0 matches → ``StepMatchError/undefined(stepText:)``
/// 5. If 2+ matches at same priority → ``StepMatchError/ambiguous(stepText:matchDescriptions:)``
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

    /// The parameter type registry for Cucumber Expression matching.
    public let registry: ParameterTypeRegistry

    /// Creates a new step executor with the default parameter type registry.
    ///
    /// - Parameter definitions: The step definitions to match against.
    public init(definitions: [StepDefinition<F>]) {
        self.definitions = definitions
        self.registry = ParameterTypeRegistry()
    }

    /// Creates a new step executor with a custom parameter type registry.
    ///
    /// - Parameters:
    ///   - definitions: The step definitions to match against.
    ///   - registry: The parameter type registry for Cucumber Expressions.
    public init(definitions: [StepDefinition<F>], registry: ParameterTypeRegistry) {
        self.definitions = definitions
        self.registry = registry
    }

    /// Matches a pickle step against the registered definitions.
    ///
    /// Delegates to ``RegexStepMatcher`` for priority-based matching
    /// across exact, Cucumber expression, and regex patterns.
    ///
    /// - Parameter step: The pickle step to match.
    /// - Returns: A ``StepMatch`` with the matched definition and captured arguments.
    /// - Throws: ``StepMatchError/undefined(stepText:)`` if no definition matches,
    ///   ``StepMatchError/ambiguous(stepText:matchDescriptions:)`` if multiple match.
    public func match(_ step: PickleStep) throws -> StepMatch<F> {
        let matcher = RegexStepMatcher(definitions: definitions, registry: registry)
        return try matcher.match(step)
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
        try await stepMatch.stepDefinition.handler(&feature, stepMatch.arguments, stepMatch.stepArgument)
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
