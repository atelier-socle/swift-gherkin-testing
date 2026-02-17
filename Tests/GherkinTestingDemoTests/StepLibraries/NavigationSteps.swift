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

import GherkinTesting
import Testing

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
