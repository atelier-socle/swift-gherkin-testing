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

/// A candidate match found during step matching.
private struct MatchCandidate<F: GherkinFeature> {
    let definition: StepDefinition<F>
    let arguments: [String]
    let priority: Int
}

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
        var candidates: [MatchCandidate<F>] = []

        for (index, compiled) in compiledPatterns.enumerated() {
            if let candidate = try tryMatch(compiled, step: step, definition: definitions[index]) {
                candidates.append(candidate)
            }
        }

        let stepArgument = StepArgument(from: step.argument)
        return try selectBestMatch(from: candidates, stepText: step.text, stepArgument: stepArgument)
    }

    /// Attempts to match a single pre-compiled pattern against a step.
    ///
    /// - Parameters:
    ///   - compiled: The pre-compiled pattern.
    ///   - step: The pickle step to match.
    ///   - definition: The step definition associated with this pattern.
    /// - Returns: A ``MatchCandidate`` if the pattern matches, `nil` otherwise.
    private func tryMatch(
        _ compiled: CompiledPattern<F>,
        step: PickleStep,
        definition: StepDefinition<F>
    ) throws -> MatchCandidate<F>? {
        switch compiled {
        case .exact(let pattern):
            return step.text == pattern ? MatchCandidate(definition: definition, arguments: [], priority: 0) : nil
        case .cucumberExpression(let expression):
            if let cucumberMatch = try expression.match(step.text) {
                return MatchCandidate(definition: definition, arguments: cucumberMatch.rawArguments, priority: 1)
            }
            return nil
        case .regex(let compiledRegex):
            if let result = try? compiledRegex.regex.wholeMatch(in: step.text) {
                return MatchCandidate(definition: definition, arguments: extractCaptures(from: result), priority: 2)
            }
            return nil
        }
    }

    /// Selects the best match from a list of candidates using priority-based resolution.
    ///
    /// - Parameters:
    ///   - candidates: All matching candidates.
    ///   - stepText: The original step text for error reporting.
    /// - Returns: A ``StepMatch`` for the best candidate.
    /// - Throws: ``StepMatchError`` if no match or ambiguous.
    private func selectBestMatch(
        from candidates: [MatchCandidate<F>],
        stepText: String,
        stepArgument: StepArgument? = nil
    ) throws -> StepMatch<F> {
        guard !candidates.isEmpty else {
            throw StepMatchError.undefined(stepText: stepText)
        }

        guard let bestPriority = candidates.min(by: { $0.priority < $1.priority })?.priority else {
            throw StepMatchError.undefined(stepText: stepText)
        }
        let bestMatches = candidates.filter { $0.priority == bestPriority }

        guard bestMatches.count == 1 else {
            let descriptions = bestMatches.map { match in
                let loc = match.definition.sourceLocation
                return "\(match.definition.patternDescription) (line \(loc.line))"
            }
            throw StepMatchError.ambiguous(stepText: stepText, matchDescriptions: descriptions)
        }

        let winner = bestMatches[0]
        return StepMatch(
            stepDefinition: winner.definition,
            arguments: winner.arguments,
            matchLocation: winner.definition.sourceLocation,
            stepArgument: stepArgument
        )
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
