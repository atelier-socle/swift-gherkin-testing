// RegistrationFeatureTests.swift
// GherkinTestingDemoTests
//
// Copyright © 2026 Atelier Socle. MIT License.

import Testing
import GherkinTesting

// MARK: - @Feature Demo: Registration with Scenario Outline + Examples

/// End-to-end demo: Registration feature with Scenario Outline expansion.
///
/// The macro generates two @Test methods:
/// - `scenario_Successful_registration()` — runs the regular scenario
/// - `scenario_Invalid_registration()` — runs all 3 expanded outline pickles
///
/// Cucumber expressions `{word}` and `{string}` are used for placeholder matching.
/// Handlers use `MockAuthService` for realistic validation flow.
@Feature(source: .inline("""
    @auth
    Feature: Registration
      New users can create an account.

      Scenario: Successful registration
        Given the user is on the registration page
        When they fill in the registration form with valid data
        And they submit the form
        Then their account is created
        And they are redirected to the welcome page

      Scenario Outline: Invalid registration
        Given the user is on the registration page
        When they fill in the <field> with "<value>"
        Then they should see the validation error "<error>"

        Examples:
          | field    | value | error                    |
          | email    |       | Email is required        |
          | password | 123   | Password is too short    |
          | username | a     | Username is too short    |
    """))
struct RegistrationFeature {
    let auth = MockAuthService()

    @Given("the user is on the registration page")
    func onRegistrationPage() async throws {
        await auth.navigateToRegistrationPage()
        let onPage = await auth.isOnRegistrationPage
        #expect(onPage)
    }

    @When("they fill in the registration form with valid data")
    func fillValidForm() async throws {
        await auth.register(email: "new@example.com", password: "secure456", username: "newuser")
    }

    @And("they submit the form")
    func submitForm() async throws {
        await Task.yield()
    }

    @Then("their account is created")
    func accountCreated() async throws {
        let complete = await auth.registrationComplete
        #expect(complete)
    }

    @And("they are redirected to the welcome page")
    func redirectedToWelcome() async throws {
        let page = await auth.currentPage
        #expect(page == "welcome")
    }

    @When("they fill in the {word} with {string}")
    func fillField(field: String, value: String) async throws {
        switch field {
        case "email":
            await auth.register(email: value, password: "secure456", username: "newuser")
        case "password":
            await auth.register(email: "test@example.com", password: value, username: "newuser")
        case "username":
            await auth.register(email: "test@example.com", password: "secure456", username: value)
        default:
            break
        }
    }

    @Then("they should see the validation error {string}")
    func seeValidationError(error: String) async throws {
        let lastError = await auth.lastError
        #expect(lastError == error)
    }
}
