// GherkinConfiguration.swift
// GherkinTesting
//
// Copyright © 2026 Atelier Socle. MIT License.

/// Configuration options for a Gherkin test run.
///
/// Controls tag filtering, dry-run mode, and reporters for output generation.
///
/// ```swift
/// let reporter = CucumberJSONReporter()
/// let config = GherkinConfiguration(
///     tagFilter: try TagFilter("@smoke and not @wip"),
///     dryRun: false,
///     reporters: [reporter]
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

    /// Creates a new configuration.
    ///
    /// - Parameters:
    ///   - tagFilter: An optional tag filter expression. Defaults to `nil` (run all).
    ///   - dryRun: Whether to run in dry-run mode. Defaults to `false`.
    ///   - reporters: The reporters to use. Defaults to empty.
    public init(
        tagFilter: TagFilter? = nil,
        dryRun: Bool = false,
        reporters: [any GherkinReporter] = []
    ) {
        self.tagFilter = tagFilter
        self.dryRun = dryRun
        self.reporters = reporters
    }

    /// A default configuration that runs all scenarios with no filtering.
    public static let `default` = GherkinConfiguration()
}
