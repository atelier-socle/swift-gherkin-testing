// StepLibraryCompositionTests.swift
// GherkinTestingDemoTests
//
// Copyright © 2026 Atelier Socle. MIT License.

import Testing
import GherkinTesting

// MARK: - Step Library Composition Demo

/// A minimal step library used to prove `stepLibraries:` composition works end-to-end.
@StepLibrary
struct GreetingSteps {
    @Given("a greeting is prepared")
    func greetingPrepared() async throws {
        await Task.yield()
    }

    @Then("the greeting is delivered")
    func greetingDelivered() async throws {
        await Task.yield()
    }
}

/// Proves that `@Feature(stepLibraries:)` composes step definitions from a library.
///
/// The feature struct has NO local step definitions — all steps are provided by
/// `GreetingSteps` via the `stepLibraries:` parameter. The macro generates:
/// ```
/// static var __stepDefinitions: [StepDefinition<Self>] {
///     var defs: [StepDefinition<Self>] = []
///     defs += GreetingSteps.__stepDefinitions.map {
///         $0.retyped(for: Self.self, using: { GreetingSteps() })
///     }
///     return defs
/// }
/// ```
@Feature(
    source: .inline("""
        Feature: Library Composition
          Scenario: Steps from library
            Given a greeting is prepared
            Then the greeting is delivered
        """),
    stepLibraries: [GreetingSteps.self]
)
struct LibraryCompositionFeature {
}
