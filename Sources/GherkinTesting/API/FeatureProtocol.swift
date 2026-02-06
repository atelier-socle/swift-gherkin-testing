// FeatureProtocol.swift
// GherkinTesting
//
// Copyright © 2026 Atelier Socle. MIT License.

/// A protocol that user-defined feature types conform to for BDD test execution.
///
/// Types conforming to `GherkinFeature` represent a Gherkin Feature file and
/// contain the step implementations as methods. The `@Feature` macro generates
/// conformance automatically.
///
/// Override ``gherkinConfiguration`` to customize execution (reporters, dry-run,
/// tag filtering):
///
/// ```swift
/// @Feature(source: .inline("..."))
/// struct LoginFeature {
///     static var gherkinConfiguration: GherkinConfiguration {
///         GherkinConfiguration(reporters: [CucumberJSONReporter()])
///     }
///
///     @Given("the user is logged in")
///     func loggedIn() { }
/// }
/// ```
public protocol GherkinFeature: Sendable {
    /// The configuration used when executing this feature's scenarios.
    ///
    /// Override this property to customize reporters, dry-run mode, or tag filtering.
    /// The default implementation returns ``GherkinConfiguration/default``.
    static var gherkinConfiguration: GherkinConfiguration { get }
}

extension GherkinFeature {
    /// Default configuration that runs all scenarios with no filtering or reporters.
    public static var gherkinConfiguration: GherkinConfiguration { .default }
}
