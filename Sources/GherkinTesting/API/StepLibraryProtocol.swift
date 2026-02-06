// StepLibraryProtocol.swift
// GherkinTesting
//
// Copyright © 2026 Atelier Socle. MIT License.

/// A protocol for reusable step definition libraries.
///
/// Types conforming to `StepLibrary` contain step definitions (decorated with
/// `@Given`, `@When`, `@Then`, etc.) that can be shared across multiple features.
/// The `@StepLibrary` macro generates the conformance and a `__stepDefinitions`
/// static property automatically.
///
/// ```swift
/// @StepLibrary
/// struct SharedAuthSteps {
///     @Given("the user is logged in")
///     mutating func loggedIn() { ... }
///
///     @When("they click logout")
///     mutating func clickLogout() { ... }
/// }
/// ```
public protocol StepLibrary: GherkinFeature {}
