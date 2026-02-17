// SPDX-License-Identifier: Apache-2.0
//
// Copyright 2026 Atelier Socle SAS
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import Foundation
import GherkinTesting
import Testing

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
