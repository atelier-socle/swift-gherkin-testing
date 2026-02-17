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
import Testing

@testable import GherkinTesting

@Suite("End-to-End Parser Tests")
struct EndToEndTests {

    let parser = GherkinParser()

    // MARK: - Helpers

    func loadFixture(language: String = "en", name: String) throws -> String {
        let bundle = Bundle.module
        guard
            let url = bundle.url(
                forResource: name,
                withExtension: "feature",
                subdirectory: "Fixtures/\(language)"
            )
        else {
            throw FixtureError.notFound("\(language)/\(name).feature")
        }
        return try String(contentsOf: url, encoding: .utf8)
    }

    // MARK: - Simple Feature

    @Test("Parse simple.feature fixture")
    func parseSimpleFixture() throws {
        let source = try loadFixture(name: "simple")
        let doc = try parser.parse(source: source)
        let feature = try #require(doc.feature)
        #expect(feature.name == "Simple feature")
        #expect(feature.scenarios.count == 1)
        #expect(feature.scenarios[0].steps.count == 3)
    }

    // MARK: - Background Feature

    @Test("Parse background.feature fixture")
    func parseBackgroundFixture() throws {
        let source = try loadFixture(name: "background")
        let doc = try parser.parse(source: source)
        let feature = try #require(doc.feature)
        #expect(feature.background != nil)
        #expect(feature.background?.steps.count == 2)
        #expect(feature.scenarios.count == 2)
    }

    // MARK: - Scenario Outline Feature

    @Test("Parse scenario-outline.feature fixture")
    func parseScenarioOutlineFixture() throws {
        let source = try loadFixture(name: "scenario-outline")
        let doc = try parser.parse(source: source)
        let feature = try #require(doc.feature)
        let outline = try #require(feature.scenarios.first)
        #expect(outline.examples.count == 2)
        #expect(outline.examples[0].tags.first?.name == "@positive")
        #expect(outline.examples[1].tags.first?.name == "@negative")
        // Unnamed examples should have nil name
        // Named examples should have non-nil name
    }

    // MARK: - Rule Feature

    @Test("Parse rule.feature fixture")
    func parseRuleFixture() throws {
        let source = try loadFixture(name: "rule")
        let doc = try parser.parse(source: source)
        let feature = try #require(doc.feature)
        #expect(feature.tags.first?.name == "@billing")
        #expect(feature.background != nil)
        #expect(feature.rules.count == 2)
        #expect(feature.rules[0].background != nil)
        #expect(feature.rules[1].background != nil)
    }

    // MARK: - Tags Feature

    @Test("Parse tags.feature fixture")
    func parseTagsFixture() throws {
        let source = try loadFixture(name: "tags")
        let doc = try parser.parse(source: source)
        let feature = try #require(doc.feature)
        #expect(feature.tags.first?.name == "@feature-tag")
        #expect(feature.scenarios.count == 2)
        #expect(feature.scenarios[0].tags.count == 2)
    }

    // MARK: - Data Table Feature

    @Test("Parse data-table.feature fixture")
    func parseDataTableFixture() throws {
        let source = try loadFixture(name: "data-table")
        let doc = try parser.parse(source: source)
        let feature = try #require(doc.feature)
        #expect(feature.scenarios.count == 2)

        // Simple data table
        let step1 = try #require(feature.scenarios[0].steps.first)
        let table = try #require(step1.dataTable)
        #expect(table.rows.count == 3)  // header + 2

        // Escaped data table
        let step2 = try #require(feature.scenarios[1].steps.first)
        let escapedTable = try #require(step2.dataTable)
        #expect(escapedTable.rows[1].cells[0].value == "pipe | char")
    }

    // MARK: - Doc String Feature

    @Test("Parse doc-string.feature fixture")
    func parseDocStringFixture() throws {
        let source = try loadFixture(name: "doc-string")
        let doc = try parser.parse(source: source)
        let feature = try #require(doc.feature)
        #expect(feature.scenarios.count == 2)

        let step1 = try #require(feature.scenarios[0].steps.first)
        let ds1 = try #require(step1.docString)
        #expect(ds1.delimiter == "\"\"\"")
        #expect(ds1.content.contains("Hello, World!"))

        let step2 = try #require(feature.scenarios[1].steps.first)
        let ds2 = try #require(step2.docString)
        #expect(ds2.delimiter == "```")
        #expect(ds2.mediaType == "json")
    }

    // MARK: - Full Spec Feature

    @Test("Parse full-spec.feature fixture")
    func parseFullSpecFixture() throws {
        let source = try loadFixture(name: "full-spec")
        let doc = try parser.parse(source: source)
        let feature = try #require(doc.feature)

        #expect(feature.tags.count == 2)
        #expect(feature.background != nil)
        #expect(feature.description != nil)
        #expect(feature.scenarios.count >= 2)  // Basic + outline
        #expect(feature.rules.count == 1)

        // Check that the rule has scenarios with docstring and data table
        let rule = feature.rules[0]
        #expect(rule.background != nil)
        #expect(rule.scenarios.count >= 2)
    }

    // MARK: - Edge Cases Feature

    @Test("Parse edge-cases.feature fixture")
    func parseEdgeCasesFixture() throws {
        let source = try loadFixture(name: "edge-cases")
        let doc = try parser.parse(source: source)
        let feature = try #require(doc.feature)
        #expect(feature.scenarios.count == 3)
        // Empty name scenario
        #expect(feature.scenarios[0].name == "")
        // Empty steps scenario
        #expect(feature.scenarios[1].steps.isEmpty)
        // Unicode scenario
        #expect(feature.scenarios[2].name.contains("Unicode"))
    }

    // MARK: - French Feature

    @Test("Parse French authentification.feature fixture")
    func parseFrenchFixture() throws {
        let source = try loadFixture(language: "fr", name: "authentification")
        let doc = try parser.parse(source: source)
        let feature = try #require(doc.feature)
        #expect(feature.language == "fr")
        #expect(feature.keyword == "Fonctionnalité")
        #expect(feature.scenarios.count == 2)
    }

    // MARK: - Japanese Feature

    @Test("Parse Japanese login.feature fixture")
    func parseJapaneseFixture() throws {
        let source = try loadFixture(language: "ja", name: "login")
        let doc = try parser.parse(source: source)
        let feature = try #require(doc.feature)
        #expect(feature.language == "ja")
        #expect(feature.scenarios.count == 1)
        #expect(feature.scenarios[0].steps.count == 3)
    }
}

/// Error for test fixture loading.
enum FixtureError: Error {
    case notFound(String)
}
