// FileSourceFeatureTests.swift
// GherkinTestingDemoTests
//
// Copyright © 2026 Atelier Socle. MIT License.

import Testing
import Foundation
import GherkinTesting

// MARK: - @Feature Demo: .file() source loading from Bundle.module

/// Demonstrates loading a `.feature` file from the test bundle's resources.
///
/// The macro generates `bundle: Bundle.module` in the `FeatureExecutor.run()` call,
/// allowing SPM test targets to resolve feature files copied via `.copy("Fixtures")`.
///
/// The feature file at `Fixtures/en/login.feature` is the same one used by
/// `LoginFeatureTests` (inline), but here it's loaded at runtime from disk.
@Feature(
    source: .file("Fixtures/en/login.feature")
)
struct FileSourceLoginFeature {
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
}
