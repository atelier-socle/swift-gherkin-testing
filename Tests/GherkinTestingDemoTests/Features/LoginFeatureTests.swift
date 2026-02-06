// LoginFeatureTests.swift
// GherkinTestingDemoTests
//
// Copyright © 2026 Atelier Socle. MIT License.

import Testing
import GherkinTesting

// MARK: - @Feature Demo: Login with Background, Cucumber Expressions, Hooks

/// End-to-end demo: Login feature using @Feature macro with realistic handlers.
///
/// The @Feature macro generates:
/// - `extension LoginFeature: GherkinFeature {}` (protocol conformance)
/// - `static var __stepDefinitions` (inside struct, collects all @Given/@When/@Then)
/// - `static var __hooks` (collects @Before/@After, passed to FeatureExecutor)
/// - `LoginFeature__GherkinTests` @Suite with per-scenario @Test methods
///
/// Step handlers use `MockAuthService` actor for realistic async state management.
@Feature(source: .inline("""
    @auth @smoke
    Feature: Login
      Users can log in with valid credentials.

      Background:
        Given the app is launched

      Scenario: Successful login
        Given the user is on the login page
        When they enter "alice" and "secret123"
        Then they should see the dashboard

      Scenario: Failed login with wrong password
        Given the user is on the login page
        When they enter "alice" and "wrong"
        Then they should see an error message
    """))
struct LoginFeature {
    let auth = MockAuthService()

    // MARK: - Hooks (wired to FeatureExecutor via __hooks)

    @Before(.scenario)
    static func setUp() async throws {
        await Task.yield()
    }

    @After(.scenario)
    static func tearDown() async throws {
        await Task.yield()
    }

    // MARK: - Step Definitions

    @Given("the app is launched")
    func appLaunched() async throws {
        await auth.launchApp()
        let launched = await auth.isAppLaunched
        #expect(launched)
    }

    @Given("the user is on the login page")
    func onLoginPage() async throws {
        await auth.navigateToLoginPage()
        let onPage = await auth.isOnLoginPage
        #expect(onPage)
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
        #expect(error == "Invalid username or password")
    }
}
