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

import Foundation

/// A protocol for receiving test execution events and generating reports.
///
/// Reporters observe the test run lifecycle and collect data for output
/// in various formats (Cucumber JSON, JUnit XML, HTML, etc.).
///
/// The callback methods are invoked in chronological order during execution:
/// 1. ``featureStarted(_:)`` — once per feature, before any scenarios run
/// 2. ``scenarioStarted(_:)`` — before each scenario's steps execute
/// 3. ``stepFinished(_:)`` — after each step completes
/// 4. ``scenarioFinished(_:)`` — after all steps in a scenario complete
/// 5. ``featureFinished(_:)`` — after all scenarios in a feature complete
/// 6. ``testRunFinished(_:)`` — once, after the entire run completes
///
/// Call ``generateReport()`` after the run to produce the formatted output.
///
/// ```swift
/// let reporter = CucumberJSONReporter()
/// let config = GherkinConfiguration(reporters: [reporter])
/// let runner = TestRunner(definitions: steps, configuration: config)
/// let result = try await runner.run(...)
/// let reportData = try await reporter.generateReport()
/// ```
public protocol GherkinReporter: Sendable {
    /// Called when a feature begins execution.
    ///
    /// - Parameter feature: The feature result (contains name and tags; scenario results are empty at this point).
    func featureStarted(_ feature: FeatureResult) async

    /// Called when a scenario begins execution.
    ///
    /// - Parameter scenario: The scenario result (contains name and tags; step results are empty at this point).
    func scenarioStarted(_ scenario: ScenarioResult) async

    /// Called after a step finishes execution.
    ///
    /// - Parameter step: The completed step result with status and duration.
    func stepFinished(_ step: StepResult) async

    /// Called after all steps in a scenario have finished.
    ///
    /// - Parameter scenario: The completed scenario result with all step results.
    func scenarioFinished(_ scenario: ScenarioResult) async

    /// Called after all scenarios in a feature have finished.
    ///
    /// - Parameter feature: The completed feature result with all scenario results.
    func featureFinished(_ feature: FeatureResult) async

    /// Called once after the entire test run completes.
    ///
    /// - Parameter result: The complete test run result.
    func testRunFinished(_ result: TestRunResult) async

    /// Generates the formatted report data.
    ///
    /// Call this after the test run completes to produce the output in the
    /// reporter's format (JSON, XML, HTML, etc.).
    ///
    /// - Returns: The report as raw bytes.
    /// - Throws: If report generation fails.
    func generateReport() async throws -> Data
}

// MARK: - Convenience

extension GherkinReporter {
    /// Generates the report and writes it to the given file URL.
    ///
    /// Creates any intermediate directories if they don't exist.
    ///
    /// - Parameter url: The file URL to write the report to.
    /// - Throws: If report generation or file writing fails.
    public func writeReport(to url: URL) async throws {
        let data = try await generateReport()
        let directory = url.deletingLastPathComponent()
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        try data.write(to: url)
    }
}
