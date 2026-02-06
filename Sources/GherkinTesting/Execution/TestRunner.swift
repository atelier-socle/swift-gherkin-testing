// TestRunner.swift
// GherkinTesting
//
// Copyright © 2026 Atelier Socle. MIT License.

/// The main test orchestrator that executes compiled pickles against step definitions.
///
/// `TestRunner` takes a list of ``Pickle`` test cases (compiled from a ``GherkinDocument``),
/// matches each step against registered ``StepDefinition`` instances, and collects
/// the results into a ``TestRunResult``.
///
/// The execution flow for each pickle:
/// 1. Evaluate the tag filter — skip the pickle if it doesn't match
/// 2. Execute before hooks (`.feature` at start, `.scenario` before each scenario)
/// 3. For each step: before step hook → match → execute → after step hook
/// 4. If a step fails, remaining steps in that scenario are marked `.skipped`
/// 5. Execute after hooks (`.scenario` after each, `.feature` at end)
/// 6. Collect results into ``TestRunResult``
///
/// In dry-run mode, steps are matched but not executed. Undefined and ambiguous
/// steps are reported without running any handlers.
///
/// The generic parameter `F` is the concrete feature type used for step execution.
///
/// ```swift
/// let runner = TestRunner<LoginFeature>(definitions: mySteps)
/// var feature = LoginFeature()
/// let result = try await runner.run(
///     pickles: pickles,
///     featureName: "Login",
///     featureTags: ["@smoke"],
///     feature: feature
/// )
/// print("Passed: \(result.passedCount), Failed: \(result.failedCount)")
/// ```
public struct TestRunner<F: GherkinFeature>: Sendable {
    /// The step definitions used for matching.
    public let definitions: [StepDefinition<F>]

    /// The lifecycle hook registry.
    public let hooks: HookRegistry

    /// The execution configuration.
    public let configuration: GherkinConfiguration

    /// Creates a new test runner.
    ///
    /// - Parameters:
    ///   - definitions: The step definitions to match against.
    ///   - hooks: The lifecycle hooks. Defaults to empty.
    ///   - configuration: The execution configuration. Defaults to ``GherkinConfiguration/default``.
    public init(
        definitions: [StepDefinition<F>],
        hooks: HookRegistry = HookRegistry(),
        configuration: GherkinConfiguration = .default
    ) {
        self.definitions = definitions
        self.hooks = hooks
        self.configuration = configuration
    }

    /// Executes all pickles and returns the aggregated test run result.
    ///
    /// Each scenario gets a fresh copy of the feature instance, ensuring
    /// isolation between scenarios. Background steps (already merged into
    /// the pickle by the compiler) execute as part of the step sequence.
    ///
    /// - Parameters:
    ///   - pickles: The compiled pickles to execute.
    ///   - featureName: The feature name for the result.
    ///   - featureTags: The feature-level tags.
    ///   - feature: The feature instance (value-copied per scenario for isolation).
    /// - Returns: A ``TestRunResult`` containing all execution results.
    /// - Throws: Errors from lifecycle hooks (step execution errors are captured in results).
    public func run(
        pickles: [Pickle],
        featureName: String,
        featureTags: [String],
        feature: F
    ) async throws -> TestRunResult {
        let executor = StepExecutor(definitions: definitions)
        let clock = ContinuousClock()
        let startTime = clock.now

        // Notify reporters: feature starting
        let startingFeature = FeatureResult(
            name: featureName,
            scenarioResults: [],
            tags: featureTags
        )
        for reporter in configuration.reporters {
            await reporter.featureStarted(startingFeature)
        }

        // Before feature hooks
        try await hooks.executeBefore(scope: .feature, tags: featureTags)

        var scenarioResults: [ScenarioResult] = []

        for pickle in pickles {
            let pickleTags = pickle.tags.map(\.name)

            // Tag filter: non-matching pickles are recorded as skipped
            if let filter = configuration.tagFilter, !filter.matches(tags: pickleTags) {
                let skippedStepResults = pickle.steps.map { step in
                    StepResult(step: step, status: .skipped, duration: .zero, location: nil)
                }
                let skippedResult = ScenarioResult(
                    name: pickle.name,
                    stepResults: skippedStepResults,
                    tags: pickleTags
                )
                // Notify reporters of skipped scenario
                for reporter in configuration.reporters {
                    await reporter.scenarioStarted(skippedResult)
                    await reporter.scenarioFinished(skippedResult)
                }
                scenarioResults.append(skippedResult)
                continue
            }

            let scenarioResult = await runScenario(
                pickle: pickle,
                pickleTags: pickleTags,
                feature: feature,
                executor: executor,
                clock: clock
            )
            scenarioResults.append(scenarioResult)
        }

        // After feature hooks (always run, even if scenarios failed)
        try? await hooks.executeAfter(scope: .feature, tags: featureTags)

        let duration = clock.now - startTime

        let featureResult = FeatureResult(
            name: featureName,
            scenarioResults: scenarioResults,
            tags: featureTags
        )

        // Notify reporters: feature finished
        for reporter in configuration.reporters {
            await reporter.featureFinished(featureResult)
        }

        let runResult = TestRunResult(
            featureResults: [featureResult],
            duration: duration
        )

        // Notify reporters: test run finished
        for reporter in configuration.reporters {
            await reporter.testRunFinished(runResult)
        }

        return runResult
    }

    /// Executes a single scenario (pickle) and returns its result.
    ///
    /// In dry-run mode, all steps are matched but not executed. Undefined steps
    /// receive suggestions. Dry-run does not skip remaining steps after an undefined.
    ///
    /// In normal mode, a failed/pending/undefined step causes remaining steps
    /// to be skipped.
    private func runScenario(
        pickle: Pickle,
        pickleTags: [String],
        feature: F,
        executor: StepExecutor<F>,
        clock: ContinuousClock
    ) async -> ScenarioResult {
        // Fresh copy per scenario for isolation
        var scenarioFeature = feature

        // Notify reporters: scenario starting
        let startingScenario = ScenarioResult(
            name: pickle.name,
            stepResults: [],
            tags: pickleTags
        )
        for reporter in configuration.reporters {
            await reporter.scenarioStarted(startingScenario)
        }

        // Before scenario hooks
        try? await hooks.executeBefore(scope: .scenario, tags: pickleTags)

        var stepResults: [StepResult] = []
        var scenarioFailed = false

        for step in pickle.steps {
            let stepResult: StepResult

            if configuration.dryRun {
                // Dry-run: match ALL steps (never skip), generate suggestions
                stepResult = dryRunStep(step, executor: executor)
            } else if scenarioFailed {
                stepResult = StepResult(step: step, status: .skipped, duration: .zero, location: nil)
            } else {
                stepResult = await executeStep(
                    step,
                    pickleTags: pickleTags,
                    feature: &scenarioFeature,
                    executor: executor,
                    clock: clock
                )
                if stepResult.status.isFailure {
                    scenarioFailed = true
                }
            }

            // Notify reporters: step finished
            for reporter in configuration.reporters {
                await reporter.stepFinished(stepResult)
            }

            stepResults.append(stepResult)
        }

        // After scenario hooks (always run, even if steps failed)
        try? await hooks.executeAfter(scope: .scenario, tags: pickleTags)

        let scenarioResult = ScenarioResult(
            name: pickle.name,
            stepResults: stepResults,
            tags: pickleTags
        )

        // Notify reporters: scenario finished
        for reporter in configuration.reporters {
            await reporter.scenarioFinished(scenarioResult)
        }

        return scenarioResult
    }

    /// Executes a single step with hooks and timing.
    ///
    /// Detects ``PendingStepError`` and maps it to ``StepStatus/pending``.
    /// Generates ``StepSuggestion`` for undefined steps.
    private func executeStep(
        _ step: PickleStep,
        pickleTags: [String],
        feature: inout F,
        executor: StepExecutor<F>,
        clock: ContinuousClock
    ) async -> StepResult {
        let stepStart = clock.now

        // Before step hooks
        try? await hooks.executeBefore(scope: .step, tags: pickleTags)

        let status: StepStatus
        var location: Location?
        var suggestion: StepSuggestion?

        do {
            let stepMatch = try executor.match(step)
            location = stepMatch.matchLocation
            try await stepMatch.stepDefinition.handler(&feature, stepMatch.arguments)
            status = .passed
        } catch is PendingStepError {
            status = .pending
        } catch let error as StepMatchError {
            status = stepMatchErrorToStatus(error)
            if case .undefined = error {
                suggestion = StepSuggestion.suggest(stepText: step.text)
            }
        } catch {
            status = .failed(StepFailure(error: error))
        }

        // After step hooks (always run, even if step failed)
        try? await hooks.executeAfter(scope: .step, tags: pickleTags)

        let duration = clock.now - stepStart
        return StepResult(
            step: step,
            status: status,
            duration: duration,
            location: location,
            suggestion: suggestion
        )
    }

    /// Matches a step without executing it (dry-run mode).
    ///
    /// Generates a ``StepSuggestion`` for undefined steps.
    private func dryRunStep(_ step: PickleStep, executor: StepExecutor<F>) -> StepResult {
        do {
            let stepMatch = try executor.match(step)
            return StepResult(
                step: step,
                status: .passed,
                duration: .zero,
                location: stepMatch.matchLocation
            )
        } catch let error as StepMatchError {
            var suggestion: StepSuggestion?
            if case .undefined = error {
                suggestion = StepSuggestion.suggest(stepText: step.text)
            }
            return StepResult(
                step: step,
                status: stepMatchErrorToStatus(error),
                duration: .zero,
                location: nil,
                suggestion: suggestion
            )
        } catch {
            return StepResult(
                step: step,
                status: .failed(StepFailure(error: error)),
                duration: .zero,
                location: nil
            )
        }
    }

    /// Converts a ``StepMatchError`` to the corresponding ``StepStatus``.
    private func stepMatchErrorToStatus(_ error: StepMatchError) -> StepStatus {
        switch error {
        case .undefined:
            return .undefined
        case .ambiguous:
            return .ambiguous
        case .typeMismatch:
            return .failed(StepFailure(error: error))
        }
    }
}
