// FeatureProtocol.swift
// GherkinTesting
//
// Copyright © 2026 Atelier Socle. MIT License.

/// A protocol that user-defined feature types conform to for BDD test execution.
///
/// Types conforming to `GherkinFeature` represent a Gherkin Feature file and
/// contain the step implementations as methods. The `@Feature` macro (Phase 4)
/// generates conformance automatically; in Phase 3, types conform manually.
///
/// ```swift
/// struct LoginFeature: GherkinFeature {
///     var loggedIn = false
///
///     mutating func givenUserIsOnLoginPage() {
///         // setup code
///     }
/// }
/// ```
public protocol GherkinFeature: Sendable {}
