// NavigationFeatureTests.swift
// GherkinTestingDemoTests
//
// Copyright © 2026 Atelier Socle. MIT License.

import Testing
import GherkinTesting

// MARK: - @Feature Demo: Navigation

/// End-to-end demo: Navigation feature using @Feature macro with async handlers.
///
/// The macro generates two @Test methods:
/// - `scenario_Navigate_to_profile()`
/// - `scenario_Navigate_to_settings()`
///
/// Handlers use `MockAuthService` for state-based navigation assertions.
@Feature(source: .inline("""
    @navigation
    Feature: Navigation
      Users can navigate between pages.

      Scenario: Navigate to profile
        Given the user is logged in
        When they tap the profile icon
        Then they should see the profile page

      Scenario: Navigate to settings
        Given the user is logged in
        When they tap the settings icon
        Then they should see the settings page
    """))
struct NavigationFeature {
    let auth = MockAuthService()

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

// MARK: - Tag Filter Demo (requires manual runtime API)

/// Demonstrates tag filtering using the runtime API with macro-generated types.
///
/// @Feature does not yet support a `tagFilter:` parameter, so tag filtering
/// requires using `TestRunner` directly. The step definitions from the
/// macro-generated `NavigationFeature.__stepDefinitions` are reused here.
@Suite("Demo: Tag Filtering")
struct TagFilterDemoTests {

    @Test("Tag filter excludes non-matching scenarios")
    func tagFilterExclusion() async throws {
        let source = try loadFixture("en/navigation.feature")
        let parser = GherkinParser()
        let document = try parser.parse(source: source)
        let pickles = PickleCompiler().compile(document)

        let config = GherkinConfiguration(tagFilter: try TagFilter("@nonexistent"))
        let runner = TestRunner(
            definitions: NavigationFeature.__stepDefinitions,
            configuration: config
        )
        let result = try await runner.run(
            pickles: pickles,
            featureName: "Navigation",
            featureTags: ["@navigation"],
            feature: NavigationFeature()
        )

        #expect(result.passedCount == 0)
        #expect(result.skippedCount == 2)
    }
}
