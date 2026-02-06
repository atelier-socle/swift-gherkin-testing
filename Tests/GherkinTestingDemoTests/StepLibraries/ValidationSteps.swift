// ValidationSteps.swift
// GherkinTestingDemoTests
//
// Copyright © 2026 Atelier Socle. MIT License.

import GherkinTesting

/// Reusable validation step definitions with async Cucumber expressions.
@StepLibrary
struct ValidationSteps {
    let auth = MockAuthService()

    @Given("the {word} field contains {string}")
    func fieldContains(field: String, value: String) async throws {
        await Task.yield()
    }

    @Then("the field {string} should be valid")
    func fieldValid(field: String) async throws {
        await Task.yield()
    }

    @Then("the field {string} should be invalid")
    func fieldInvalid(field: String) async throws {
        await Task.yield()
    }
}
