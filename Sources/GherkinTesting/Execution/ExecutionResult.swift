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

/// A description of a step failure for diagnostic reporting.
///
/// Wraps error information as a plain string so that ``StepStatus`` and
/// result types remain `Sendable` and `Equatable`.
public struct StepFailure: Sendable, Equatable, Hashable {
    /// A human-readable description of the failure.
    public let message: String

    /// Creates a step failure with the given message.
    ///
    /// - Parameter message: A description of what went wrong.
    public init(message: String) {
        self.message = message
    }

    /// Creates a step failure from an arbitrary error.
    ///
    /// - Parameter error: The error whose description becomes the message.
    public init(error: any Error) {
        self.message = String(describing: error)
    }
}

/// The execution status of a single step.
///
/// Status values are ordered by severity for aggregation:
/// `.passed` < `.skipped` < `.pending` < `.undefined` < `.ambiguous` < `.failed`.
@frozen
public enum StepStatus: Sendable, Equatable, Hashable {
    /// The step executed successfully.
    case passed

    /// The step failed with the given failure description.
    case failed(StepFailure)

    /// The step was skipped because a prior step in the same scenario failed.
    case skipped

    /// The step is marked as pending (implementation not yet provided).
    case pending

    /// No step definition was found for the step text.
    case undefined

    /// Multiple step definitions match the step text.
    case ambiguous

    /// The severity priority of this status (higher = worse).
    var priority: Int {
        switch self {
        case .passed: return 0
        case .skipped: return 1
        case .pending: return 2
        case .undefined: return 3
        case .ambiguous: return 4
        case .failed: return 5
        }
    }

    /// Whether this status represents a non-passing outcome.
    public var isFailure: Bool {
        switch self {
        case .passed: return false
        default: return true
        }
    }
}

/// The result of executing a single step.
public struct StepResult: Sendable, Equatable {
    /// The pickle step that was executed.
    public let step: PickleStep

    /// The execution status of the step.
    public let status: StepStatus

    /// The wall-clock duration of step execution.
    public let duration: Duration

    /// The source location of the matched step definition, if any.
    public let location: Location?

    /// A code suggestion for undefined steps.
    ///
    /// When a step's status is ``StepStatus/undefined``, this contains a
    /// suggested Cucumber expression and code skeleton that the user can
    /// copy-paste to define the missing step.
    public let suggestion: StepSuggestion?

    /// Creates a new step result.
    ///
    /// - Parameters:
    ///   - step: The pickle step that was executed.
    ///   - status: The execution status.
    ///   - duration: The wall-clock execution duration.
    ///   - location: The source location of the matched definition.
    ///   - suggestion: A code suggestion for undefined steps. Defaults to `nil`.
    public init(
        step: PickleStep,
        status: StepStatus,
        duration: Duration,
        location: Location?,
        suggestion: StepSuggestion? = nil
    ) {
        self.step = step
        self.status = status
        self.duration = duration
        self.location = location
        self.suggestion = suggestion
    }
}

/// The result of executing all steps in a single scenario (pickle).
public struct ScenarioResult: Sendable, Equatable {
    /// The scenario name.
    public let name: String

    /// The results for each step in execution order.
    public let stepResults: [StepResult]

    /// The tags applied to this scenario (inherited from Feature, Rule, Examples).
    public let tags: [String]

    /// Creates a new scenario result.
    ///
    /// - Parameters:
    ///   - name: The scenario name.
    ///   - stepResults: The ordered step results.
    ///   - tags: The scenario tags.
    public init(name: String, stepResults: [StepResult], tags: [String]) {
        self.name = name
        self.stepResults = stepResults
        self.tags = tags
    }

    /// The aggregate status derived from step results.
    ///
    /// Returns the worst (highest priority) status among all steps.
    /// An empty scenario is considered `.passed`.
    public var status: StepStatus {
        stepResults.reduce(StepStatus.passed) { worst, result in
            result.status.priority > worst.priority ? result.status : worst
        }
    }

    /// The total duration across all steps.
    public var duration: Duration {
        stepResults.reduce(Duration.zero) { $0 + $1.duration }
    }
}

/// The result of executing all scenarios in a single feature.
public struct FeatureResult: Sendable, Equatable {
    /// The feature name.
    public let name: String

    /// The results for each scenario in execution order.
    public let scenarioResults: [ScenarioResult]

    /// The tags applied to this feature.
    public let tags: [String]

    /// Creates a new feature result.
    ///
    /// - Parameters:
    ///   - name: The feature name.
    ///   - scenarioResults: The ordered scenario results.
    ///   - tags: The feature tags.
    public init(name: String, scenarioResults: [ScenarioResult], tags: [String]) {
        self.name = name
        self.scenarioResults = scenarioResults
        self.tags = tags
    }

    /// The aggregate status derived from scenario results.
    ///
    /// Returns the worst (highest priority) status among all scenarios.
    /// A feature with no scenarios is considered `.passed`.
    public var status: StepStatus {
        scenarioResults.reduce(StepStatus.passed) { worst, result in
            result.status.priority > worst.priority ? result.status : worst
        }
    }

    /// The total duration across all scenarios.
    public var duration: Duration {
        scenarioResults.reduce(Duration.zero) { $0 + $1.duration }
    }
}

/// The result of a complete test run across one or more features.
public struct TestRunResult: Sendable, Equatable {
    /// The results for each feature in execution order.
    public let featureResults: [FeatureResult]

    /// The total wall-clock duration of the test run.
    public let duration: Duration

    /// Creates a new test run result.
    ///
    /// - Parameters:
    ///   - featureResults: The ordered feature results.
    ///   - duration: The total duration.
    public init(featureResults: [FeatureResult], duration: Duration) {
        self.featureResults = featureResults
        self.duration = duration
    }

    /// The number of scenarios that passed.
    public var passedCount: Int {
        featureResults.flatMap(\.scenarioResults).filter { $0.status == .passed }.count
    }

    /// The number of scenarios that failed.
    public var failedCount: Int {
        featureResults.flatMap(\.scenarioResults).filter {
            if case .failed = $0.status { return true }
            return false
        }.count
    }

    /// The number of scenarios that were skipped.
    public var skippedCount: Int {
        featureResults.flatMap(\.scenarioResults).filter { $0.status == .skipped }.count
    }

    /// The number of scenarios with pending steps.
    public var pendingCount: Int {
        featureResults.flatMap(\.scenarioResults).filter { $0.status == .pending }.count
    }

    /// The number of scenarios with undefined steps.
    public var undefinedCount: Int {
        featureResults.flatMap(\.scenarioResults).filter { $0.status == .undefined }.count
    }

    /// The total number of scenarios executed (including skipped).
    public var totalCount: Int {
        featureResults.flatMap(\.scenarioResults).count
    }

    /// All step suggestions collected from undefined steps across the entire run.
    ///
    /// Particularly useful in dry-run mode where all steps are matched
    /// and suggestions are generated for every undefined step.
    public var allSuggestions: [StepSuggestion] {
        featureResults
            .flatMap(\.scenarioResults)
            .flatMap(\.stepResults)
            .compactMap(\.suggestion)
    }
}
