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

/// Configuration options for a Gherkin test run.
///
/// Controls tag filtering, dry-run mode, reporters for output generation,
/// and custom Cucumber Expression parameter types.
///
/// ```swift
/// let reporter = CucumberJSONReporter()
/// let config = GherkinConfiguration(
///     reporters: [reporter],
///     parameterTypes: [
///         .type("color", matching: "red|green|blue")
///     ],
///     tagFilter: try TagFilter("@smoke and not @wip"),
///     dryRun: false
/// )
/// let runner = TestRunner(
///     definitions: mySteps,
///     configuration: config
/// )
/// ```
public struct GherkinConfiguration: Sendable {
    /// An optional tag filter to restrict which scenarios are executed.
    ///
    /// When set, only pickles whose tags satisfy this filter are executed.
    /// Pickles that don't match are silently skipped.
    public var tagFilter: TagFilter?

    /// Whether to run in dry-run mode.
    ///
    /// In dry-run mode, steps are matched against definitions but their
    /// handlers are not executed. This is useful for validating that all
    /// steps have matching definitions without side effects.
    public var dryRun: Bool

    /// The reporters that receive execution events and generate reports.
    ///
    /// Reporters are notified of feature, scenario, and step lifecycle
    /// events during execution. After the run completes, call
    /// ``GherkinReporter/generateReport()`` on each reporter to produce output.
    public var reporters: [any GherkinReporter]

    /// Custom Cucumber Expression parameter types.
    ///
    /// These types are registered in the ``ParameterTypeRegistry`` before
    /// step matching begins. Use ``ParameterTypeDescriptor/type(_:matching:)``
    /// to declare custom types:
    ///
    /// ```swift
    /// let config = GherkinConfiguration(
    ///     parameterTypes: [
    ///         .type("color", matching: "red|green|blue")
    ///     ]
    /// )
    /// ```
    ///
    /// Custom types are matched as strings. If a descriptor's name conflicts
    /// with a built-in type (`int`, `float`, `string`, `word`), the built-in
    /// type takes precedence and the descriptor is silently skipped.
    public var parameterTypes: [ParameterTypeDescriptor]

    /// Creates a new configuration.
    ///
    /// - Parameters:
    ///   - reporters: The reporters to use. Defaults to empty.
    ///   - parameterTypes: Custom Cucumber Expression parameter types. Defaults to empty.
    ///   - tagFilter: An optional tag filter expression. Defaults to `nil` (run all).
    ///   - dryRun: Whether to run in dry-run mode. Defaults to `false`.
    public init(
        reporters: [any GherkinReporter] = [],
        parameterTypes: [ParameterTypeDescriptor] = [],
        tagFilter: TagFilter? = nil,
        dryRun: Bool = false
    ) {
        self.reporters = reporters
        self.parameterTypes = parameterTypes
        self.tagFilter = tagFilter
        self.dryRun = dryRun
    }

    /// A default configuration that runs all scenarios with no filtering.
    public static let `default` = GherkinConfiguration()
}
