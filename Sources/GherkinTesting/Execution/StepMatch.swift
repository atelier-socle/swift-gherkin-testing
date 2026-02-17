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

    /// The step argument (DataTable or DocString) from the pickle step, if present.
    public let stepArgument: StepArgument?

    /// Creates a new step match result.
    ///
    /// - Parameters:
    ///   - stepDefinition: The matched step definition.
    ///   - arguments: The captured argument strings.
    ///   - matchLocation: The source location of the definition.
    ///   - stepArgument: The step argument from the pickle step.
    public init(
        stepDefinition: StepDefinition<F>,
        arguments: [String],
        matchLocation: Location,
        stepArgument: StepArgument? = nil
    ) {
        self.stepDefinition = stepDefinition
        self.arguments = arguments
        self.matchLocation = matchLocation
        self.stepArgument = stepArgument
    }
}
