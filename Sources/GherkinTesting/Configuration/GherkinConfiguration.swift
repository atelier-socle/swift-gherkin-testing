// GherkinConfiguration.swift
// GherkinTesting
//
// Copyright © 2026 Atelier Socle. MIT License.

/// Configuration options for a Gherkin test run.
///
/// Controls tag filtering, dry-run mode, and other execution behaviors.
/// Reporters will be added in Phase 7.
///
/// ```swift
/// let config = GherkinConfiguration(
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

    /// Creates a new configuration.
    ///
    /// - Parameters:
    ///   - tagFilter: An optional tag filter expression. Defaults to `nil` (run all).
    ///   - dryRun: Whether to run in dry-run mode. Defaults to `false`.
    public init(
        tagFilter: TagFilter? = nil,
        dryRun: Bool = false
    ) {
        self.tagFilter = tagFilter
        self.dryRun = dryRun
    }

    /// A default configuration that runs all scenarios with no filtering.
    public static let `default` = GherkinConfiguration()
}
