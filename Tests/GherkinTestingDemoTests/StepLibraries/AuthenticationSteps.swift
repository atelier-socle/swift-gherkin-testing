// AuthenticationSteps.swift
// GherkinTestingDemoTests
//
// Copyright © 2026 Atelier Socle. MIT License.

import GherkinTesting
import Testing

// MARK: - @StepLibrary Demo
//
// `@StepLibrary` generates `StepLibrary` conformance and a `__stepDefinitions`
// property that collects all step definitions in this struct.
//
// Step libraries can be composed into a @Feature via the `stepLibraries:` parameter:
//   @Feature(source: .file("login.feature"), stepLibraries: [AuthenticationSteps.self])
//   struct LoginFeature { }

/// Reusable authentication step definitions with async handlers.
@StepLibrary
struct AuthenticationSteps {
    let auth = MockAuthService()

    @Given("the app is launched")
    func appLaunched() async throws {
        await auth.launchApp()
    }

    @Given("the user is on the login page")
    func onLoginPage() async throws {
        await auth.navigateToLoginPage()
    }

    @When("they enter {string} and {string}")
    func enterCredentials(username: String, password: String) async throws {
        await auth.login(username: username, password: password)
    }

    @Then("they should see the dashboard")
    func seeDashboard() async throws {
        let page = await auth.currentPage
        #expect(page == "dashboard")
    }

    @Then("they should see an error message")
    func seeError() async throws {
        let error = await auth.lastError
        #expect(error != nil)
    }

    @Given("the user is on the registration page")
    func onRegistrationPage() async throws {
        await auth.navigateToRegistrationPage()
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
        await auth.register(email: value, password: "secure456", username: "newuser")
    }

    @Then("they should see the validation error {string}")
    func seeValidationError(error: String) async throws {
        let lastError = await auth.lastError
        #expect(lastError == error)
    }
}
