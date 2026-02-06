// LoginFeatureTests.swift
// GherkinTestingDemoTests
//
// Copyright © 2026 Atelier Socle. MIT License.

import Testing
import GherkinTesting

// MARK: - @Feature Demo: Login with Background, Cucumber Expressions, Hooks

/// End-to-end demo: Login feature using @Feature macro with realistic handlers.
///
/// Demonstrates:
/// - Background steps
/// - Cucumber expressions (`{string}`)
/// - `@But` step macro
/// - `@Before`/`@After` at all scopes: `.feature`, `.scenario`, `.step`
/// - `@Before` with `tags:` parameter for conditional hooks
/// - Hook ordering via `order:` parameter
/// - Async step handlers with `MockAuthService` actor
/// - `#expect` assertions in step handlers
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
        But they should not see the admin panel

      Scenario: Failed login with wrong password
        Given the user is on the login page
        When they enter "alice" and "wrong"
        Then they should see an error message
    """))
struct LoginFeature {
    let auth = MockAuthService()

    // MARK: - Feature-level Hooks

    @Before(.feature)
    static func featureSetUp() async throws {
        await Task.yield()
    }

    @After(.feature)
    static func featureTearDown() async throws {
        await Task.yield()
    }

    // MARK: - Scenario-level Hooks (with ordering)

    @Before(.scenario, order: 10)
    static func setUp() async throws {
        await Task.yield()
    }

    @Before(.scenario, order: 20)
    static func lateSetUp() async throws {
        await Task.yield()
    }

    @After(.scenario)
    static func tearDown() async throws {
        await Task.yield()
    }

    // MARK: - Conditional Hook (tags)

    @Before(.scenario, tags: "@smoke")
    static func smokeSetUp() async throws {
        await Task.yield()
    }

    // MARK: - Step-level Hooks

    @Before(.step)
    static func stepSetUp() async throws {
        await Task.yield()
    }

    @After(.step)
    static func stepTearDown() async throws {
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

    @But("they should not see the admin panel")
    func noAdminPanel() async throws {
        let page = await auth.currentPage
        #expect(page != "admin")
    }
}
