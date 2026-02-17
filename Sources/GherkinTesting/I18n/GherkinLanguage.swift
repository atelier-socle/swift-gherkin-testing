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

/// A set of localized keywords for a single Gherkin language.
///
/// Each language defines keywords for all Gherkin constructs (Feature, Scenario,
/// Given, When, Then, etc.). Step keywords include a trailing space and the
/// wildcard `"* "` keyword is included in `and`, `but`, `given`, `when`, and `then`.
///
/// ```swift
/// let english = LanguageRegistry.language(for: "en")
/// print(english?.feature) // ["Feature", "Business Need", "Ability"]
/// ```
public struct GherkinLanguage: Sendable, Equatable, Hashable {
    /// The ISO language code (e.g. `"en"`, `"fr"`, `"ja"`).
    public let code: String

    /// The English name of the language (e.g. `"English"`, `"French"`).
    public let name: String

    /// The native name of the language (e.g. `"English"`, `"français"`).
    public let native: String

    /// Keywords for the `Feature` keyword (e.g. `["Feature", "Business Need", "Ability"]`).
    public let feature: [String]

    /// Keywords for the `Rule` keyword.
    public let rule: [String]

    /// Keywords for the `Background` keyword.
    public let background: [String]

    /// Keywords for the `Scenario` keyword (includes `Example`).
    public let scenario: [String]

    /// Keywords for the `Scenario Outline` keyword (includes `Scenario Template`).
    public let scenarioOutline: [String]

    /// Keywords for the `Examples` keyword (includes `Scenarios`).
    public let examples: [String]

    /// Keywords for the `Given` step keyword (includes `"* "`).
    public let given: [String]

    /// Keywords for the `When` step keyword (includes `"* "`).
    public let when: [String]

    /// Keywords for the `Then` step keyword (includes `"* "`).
    public let then: [String]

    /// Keywords for the `And` step keyword (includes `"* "`).
    public let and: [String]

    /// Keywords for the `But` step keyword (includes `"* "`).
    public let but: [String]

    /// Creates a new Gherkin language definition.
    ///
    /// - Parameters:
    ///   - code: The ISO language code.
    ///   - name: The English name of the language.
    ///   - native: The native name of the language.
    ///   - feature: Keywords for Feature.
    ///   - rule: Keywords for Rule.
    ///   - background: Keywords for Background.
    ///   - scenario: Keywords for Scenario.
    ///   - scenarioOutline: Keywords for Scenario Outline.
    ///   - examples: Keywords for Examples.
    ///   - given: Keywords for Given steps.
    ///   - when: Keywords for When steps.
    ///   - then: Keywords for Then steps.
    ///   - and: Keywords for And steps.
    ///   - but: Keywords for But steps.
    public init(
        code: String,
        name: String,
        native: String,
        feature: [String],
        rule: [String],
        background: [String],
        scenario: [String],
        scenarioOutline: [String],
        examples: [String],
        given: [String],
        when: [String],
        then: [String],
        and: [String],
        but: [String]
    ) {
        self.code = code
        self.name = name
        self.native = native
        self.feature = feature
        self.rule = rule
        self.background = background
        self.scenario = scenario
        self.scenarioOutline = scenarioOutline
        self.examples = examples
        self.given = given
        self.when = when
        self.then = then
        self.and = and
        self.but = but
    }

    /// All step keywords for this language, combining given, when, then, and, and but.
    ///
    /// - Returns: An array of all step keyword strings.
    public var allStepKeywords: [String] {
        given + when + then + and + but
    }

    /// All non-step keywords: feature, rule, background, scenario, scenarioOutline, examples.
    ///
    /// - Returns: An array of all structural keyword strings.
    public var allStructuralKeywords: [String] {
        feature + rule + background + scenario + scenarioOutline + examples
    }
}
