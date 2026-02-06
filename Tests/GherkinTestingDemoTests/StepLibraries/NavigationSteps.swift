// NavigationSteps.swift
// GherkinTestingDemoTests
//
// Copyright © 2026 Atelier Socle. MIT License.

import Testing
import GherkinTesting

/// Reusable navigation step definitions with async handlers.
@StepLibrary
struct NavigationSteps {
    let auth = MockAuthService()

    @Given("the user is logged in")
    func userLoggedIn() async throws {
        await auth.launchApp()
        await auth.login(username: "alice", password: "secret123")
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
