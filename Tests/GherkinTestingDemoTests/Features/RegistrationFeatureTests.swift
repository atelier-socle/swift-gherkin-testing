// RegistrationFeatureTests.swift
// GherkinTestingDemoTests
//
// Copyright © 2026 Atelier Socle. MIT License.

import GherkinTesting
import Testing

// MARK: - @Feature Demo: Registration with Scenario Outline, Data Table, Typed Params

/// End-to-end demo: Registration feature with Scenario Outline expansion,
/// Data Tables, and typed parameter extraction via `{int}` and `{float}`.
///
/// Demonstrates:
/// - Scenario Outline with Examples table (placeholder substitution)
/// - Data Tables attached to steps
/// - `{int}` Cucumber expression with Int extraction
/// - `{float}` Cucumber expression with Double extraction
/// - `{word}` and `{string}` Cucumber expressions
/// - `@And` step macro
/// - `#expect` assertions with typed values
@Feature(
    source: .inline(
        """
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

          Scenario: Validation rules summary
            Given the following validation rules:
              | field    | minLength | required |
              | email    | 0         | true     |
              | password | 6         | false    |
              | username | 2         | false    |
            Then there are 3 rules loaded

          Scenario: Password strength scoring
            Given a password "secure456"
            Then the password strength is 8.5 out of 10
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

    // MARK: - Data Table + {int} demo

    @Given("the following validation rules:")
    func validationRules() async throws {
        await Task.yield()
    }

    @Then("there are {int} rules loaded")
    func rulesLoaded(count: String) async throws {
        let value = try #require(Int(count))
        #expect(value == 3)
    }

    // MARK: - {float} demo

    @Given("a password {string}")
    func aPassword(password: String) async throws {
        #expect(!password.isEmpty)
    }

    @Then("the password strength is {float} out of {int}")
    func passwordStrength(score: String, maxScore: String) async throws {
        let scoreValue = try #require(Double(score))
        let maxValue = try #require(Int(maxScore))
        #expect(scoreValue > 0.0)
        #expect(maxValue == 10)
    }
}
