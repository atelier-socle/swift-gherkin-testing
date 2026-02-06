// NavigationFeatureTests.swift
// GherkinTestingDemoTests
//
// Copyright © 2026 Atelier Socle. MIT License.

import Testing
import GherkinTesting

// MARK: - @Feature Demo: Navigation with Tag Filtering via gherkinConfiguration

/// End-to-end demo: Navigation feature using @Feature macro with tag filtering.
///
/// Demonstrates:
/// - Tag filtering via `gherkinConfiguration` (not a separate @Suite)
/// - `@wip` tag on a scenario to exclude it from execution
/// - `tagFilter: "not @wip"` in configuration
/// - Multiple scenarios in a single feature
/// - Async handlers with `MockAuthService` actor
@Feature(source: .inline("""
    @navigation
    Feature: Navigation
      Users can navigate between pages.

      Scenario: Navigate to profile
        Given the user is logged in
        When they tap the profile icon
        Then they should see the profile page

      @wip
      Scenario: Navigate to settings
        Given the user is logged in
        When they tap the settings icon
        Then they should see the settings page
    """))
struct NavigationFeature {
    let auth = MockAuthService()

    static var gherkinConfiguration: GherkinConfiguration {
        GherkinConfiguration(tagFilter: try? TagFilter("not @wip"))
    }

    @Given("the user is logged in")
    func userLoggedIn() async throws {
        await auth.launchApp()
        await auth.login(username: "alice", password: "secret123")
        let user = await auth.loggedInUser
        #expect(user == "alice")
    }

    @When("they tap the profile icon")
    func tapProfile() async throws {
        await auth.navigate(to: "profile")
    }

    @Then("they should see the profile page")
    func seeProfile() async throws {
        let page = await auth.currentPage
        #expect(page == "profile")
    }

    @When("they tap the settings icon")
    func tapSettings() async throws {
        await auth.navigate(to: "settings")
    }

    @Then("they should see the settings page")
    func seeSettings() async throws {
        let page = await auth.currentPage
        #expect(page == "settings")
    }
}
