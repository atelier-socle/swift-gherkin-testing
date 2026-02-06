// FeatureSource.swift
// GherkinTesting
//
// Copyright © 2026 Atelier Socle. MIT License.

/// The source of a Gherkin feature for parsing and execution.
///
/// A `FeatureSource` specifies where the Gherkin text comes from:
/// - ``inline(_:)`` for a string literal embedded directly in the source code
/// - ``file(_:)`` for a `.feature` file path resolved at runtime
///
/// ```swift
/// @Feature(source: .inline("""
///     Feature: Login
///       Scenario: Successful login
///         Given the user is on the login page
///         When they enter valid credentials
///         Then they should see the dashboard
///     """))
/// struct LoginFeature { ... }
///
/// @Feature(source: .file("Features/login.feature"))
/// struct LoginFeatureFromFile { ... }
/// ```
@frozen
public enum FeatureSource: Sendable, Equatable, Hashable {
    /// A Gherkin source embedded as a string literal.
    ///
    /// The macro can extract scenario names at compile time for per-scenario `@Test` methods.
    /// - Parameter source: The complete Gherkin text.
    case inline(String)

    /// A path to a `.feature` file resolved at runtime.
    ///
    /// The file is parsed at runtime; only a single `@Test` method is generated.
    /// - Parameter path: The file path relative to the test bundle or an absolute path.
    case file(String)
}
