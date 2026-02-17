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

// MARK: - @Feature Demo: i18n with French Keywords

/// End-to-end demo: French feature using @Feature macro with i18n support.
///
/// The parser detects `# language: fr` and uses French keywords (Fonctionnalite,
/// Scenario, Soit, Quand, Alors). Step definitions match by text after keyword
/// stripping — the pattern language is independent of the Gherkin language.
///
/// With i18n support in `extractScenarioNames`, French features now generate
/// per-scenario tests (e.g. `scenario_Connexion_réussie()`).
@Feature(
    source: .inline(
        """
        # language: fr
        @auth
        Fonctionnalité: Authentification
          Les utilisateurs peuvent se connecter.

          Scénario: Connexion réussie
            Soit l'application est lancée
            Quand l'utilisateur entre "alice" et "secret123"
            Alors il devrait voir le tableau de bord
        """))
struct FrenchAuthFeature {
    let auth = MockAuthService()

    @Given("l'application est lancée")
    func appLaunched() async throws {
        await auth.launchApp()
        let launched = await auth.isAppLaunched
        #expect(launched)
    }

    @When("l'utilisateur entre {string} et {string}")
    func enterCredentials(username: String, password: String) async throws {
        await auth.login(username: username, password: password)
    }

    @Then("il devrait voir le tableau de bord")
    func seeDashboard() async throws {
        let page = await auth.currentPage
        #expect(page == "dashboard")
    }
}
