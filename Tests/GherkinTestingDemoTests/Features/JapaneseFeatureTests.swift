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

// MARK: - @Feature Demo: i18n — Japanese (# language: ja)

/// Demonstrates i18n support with Japanese Gherkin keywords.
///
/// Uses `# language: ja` directive with native Japanese keywords:
/// - `機能` (Feature)
/// - `シナリオ` (Scenario)
/// - `前提` (Given) — no trailing space in keyword, text follows directly
/// - `もし` (When)
/// - `ならば` (Then)
///
/// Note: Japanese step keywords in gherkin-languages.json do NOT include
/// a trailing space (unlike English `"Given "` or French `"Soit "`).
/// The step text follows directly after the keyword without a space separator.
@Feature(
    source: .inline(
        """
        # language: ja
        @auth
        機能: ログイン
          ユーザーは有効な資格情報でログインできます。

          シナリオ: 正常ログイン
            前提アプリが起動している
            もしユーザーが "alice" と "secret123" を入力する
            ならばダッシュボードが表示される
        """))
struct JapaneseLoginFeature {
    let auth = MockAuthService()

    @Given("アプリが起動している")
    func appLaunched() async throws {
        await auth.launchApp()
        let launched = await auth.isAppLaunched
        #expect(launched)
    }

    @When("ユーザーが {string} と {string} を入力する")
    func enterCredentials(username: String, password: String) async throws {
        await auth.login(username: username, password: password)
    }

    @Then("ダッシュボードが表示される")
    func seeDashboard() async throws {
        let page = await auth.currentPage
        #expect(page == "dashboard")
    }
}
