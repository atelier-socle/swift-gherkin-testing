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

import Testing

@testable import GherkinTesting

@Suite("AST Type Tests")
struct ASTTests {

    // MARK: - Location

    @Test("Location equality")
    func locationEquality() {
        let a = Location(line: 1, column: 5)
        let b = Location(line: 1, column: 5)
        let c = Location(line: 2, column: 5)
        #expect(a == b)
        #expect(a != c)
    }

    @Test("Location default column is 0")
    func locationDefaultColumn() {
        let loc = Location(line: 3)
        #expect(loc.column == 0)
    }

    @Test("Location hashable")
    func locationHashable() {
        let a = Location(line: 1, column: 1)
        let b = Location(line: 1, column: 1)
        let set: Set<Location> = [a, b]
        #expect(set.count == 1)
    }

    // MARK: - Tag

    @Test("Tag creation and equality")
    func tagCreation() {
        let tag = Tag(location: Location(line: 1, column: 1), name: "@smoke")
        #expect(tag.name == "@smoke")
        let tag2 = Tag(location: Location(line: 1, column: 1), name: "@smoke")
        #expect(tag == tag2)
    }

    // MARK: - Comment

    @Test("Comment creation")
    func commentCreation() {
        let comment = Comment(location: Location(line: 5), text: "# my comment")
        #expect(comment.text == "# my comment")
        #expect(comment.location.line == 5)
    }

    // MARK: - StepKeywordType

    @Test("StepKeywordType raw values")
    func stepKeywordTypeRawValues() {
        #expect(StepKeywordType.context.rawValue == "context")
        #expect(StepKeywordType.action.rawValue == "action")
        #expect(StepKeywordType.outcome.rawValue == "outcome")
        #expect(StepKeywordType.conjunction.rawValue == "conjunction")
        #expect(StepKeywordType.unknown.rawValue == "unknown")
    }

    // MARK: - Step

    @Test("Step creation with no arguments")
    func stepNoArgs() {
        let step = Step(
            location: Location(line: 1),
            keyword: "Given ",
            keywordType: .context,
            text: "a precondition",
            docString: nil,
            dataTable: nil
        )
        #expect(step.keyword == "Given ")
        #expect(step.keywordType == .context)
        #expect(step.text == "a precondition")
        #expect(step.docString == nil)
        #expect(step.dataTable == nil)
    }

    // MARK: - TableCell and TableRow

    @Test("TableCell and TableRow")
    func tableCellAndRow() {
        let cell1 = TableCell(location: Location(line: 1, column: 3), value: "name")
        let cell2 = TableCell(location: Location(line: 1, column: 10), value: "email")
        let row = TableRow(location: Location(line: 1), cells: [cell1, cell2])
        #expect(row.cells.count == 2)
        #expect(row.cells[0].value == "name")
    }

    // MARK: - DataTable

    @Test("DataTable creation")
    func dataTableCreation() {
        let row = TableRow(
            location: Location(line: 1),
            cells: [
                TableCell(location: Location(line: 1, column: 3), value: "x")
            ])
        let table = DataTable(location: Location(line: 1), rows: [row])
        #expect(table.rows.count == 1)
    }

    // MARK: - DocString

    @Test("DocString creation")
    func docStringCreation() {
        let ds = DocString(
            location: Location(line: 1),
            mediaType: "json",
            content: "{\"key\": \"value\"}",
            delimiter: "\"\"\""
        )
        #expect(ds.mediaType == "json")
        #expect(ds.content == "{\"key\": \"value\"}")
        #expect(ds.delimiter == "\"\"\"")
    }

    // MARK: - Examples

    @Test("Examples creation with name")
    func examplesCreation() {
        let header = TableRow(
            location: Location(line: 1),
            cells: [
                TableCell(location: Location(line: 1, column: 3), value: "x")
            ])
        let ex = Examples(
            location: Location(line: 1),
            tags: [],
            keyword: "Examples",
            name: "Test",
            description: nil,
            tableHeader: header,
            tableBody: []
        )
        #expect(ex.name == "Test")
        #expect(ex.tableBody.isEmpty)
    }

    @Test("Examples name is nil when unnamed")
    func examplesNilName() {
        let ex = Examples(
            location: Location(line: 1),
            tags: [],
            keyword: "Examples",
            name: nil,
            description: nil,
            tableHeader: nil,
            tableBody: []
        )
        #expect(ex.name == nil)
    }

    // MARK: - Background

    @Test("Background creation")
    func backgroundCreation() {
        let bg = Background(
            location: Location(line: 1),
            keyword: "Background",
            name: "",
            description: nil,
            steps: []
        )
        #expect(bg.keyword == "Background")
        #expect(bg.steps.isEmpty)
    }

    // MARK: - Scenario

    @Test("Scenario creation")
    func scenarioCreation() {
        let scenario = Scenario(
            location: Location(line: 1),
            tags: [Tag(location: Location(line: 1), name: "@test")],
            keyword: "Scenario",
            name: "Test scenario",
            description: nil,
            steps: [],
            examples: []
        )
        #expect(scenario.name == "Test scenario")
        #expect(scenario.tags.count == 1)
        #expect(scenario.examples.isEmpty)
    }

    // MARK: - FeatureChild and RuleChild

    @Test("FeatureChild enum cases")
    func featureChildCases() {
        let bg = Background(location: Location(line: 1), keyword: "Background", name: "", description: nil, steps: [])
        let scenario = Scenario(location: Location(line: 2), tags: [], keyword: "Scenario", name: "S1", description: nil, steps: [], examples: [])
        let rule = Rule(location: Location(line: 3), tags: [], keyword: "Rule", name: "R1", description: nil, children: [])

        let children: [FeatureChild] = [.background(bg), .scenario(scenario), .rule(rule)]
        #expect(children.count == 3)

        // Test extraction
        if case .background(let extracted) = children[0] {
            #expect(extracted.keyword == "Background")
        } else {
            Issue.record("Expected .background")
        }
    }

    @Test("RuleChild enum cases")
    func ruleChildCases() {
        let bg = Background(location: Location(line: 1), keyword: "Background", name: "", description: nil, steps: [])
        let scenario = Scenario(location: Location(line: 2), tags: [], keyword: "Scenario", name: "S1", description: nil, steps: [], examples: [])

        let children: [RuleChild] = [.background(bg), .scenario(scenario)]
        #expect(children.count == 2)
    }

    // MARK: - Rule

    @Test("Rule creation with children")
    func ruleCreation() {
        let rule = Rule(
            location: Location(line: 1),
            tags: [],
            keyword: "Rule",
            name: "Business rule",
            description: nil,
            children: []
        )
        #expect(rule.name == "Business rule")
        #expect(rule.background == nil)
        #expect(rule.scenarios.isEmpty)
    }

    // MARK: - Feature

    @Test("Feature creation with children")
    func featureCreation() {
        let feature = Feature(
            location: Location(line: 1),
            tags: [],
            language: "en",
            keyword: "Feature",
            name: "My feature",
            description: nil,
            children: []
        )
        #expect(feature.name == "My feature")
        #expect(feature.language == "en")
        #expect(feature.background == nil)
        #expect(feature.scenarios.isEmpty)
        #expect(feature.rules.isEmpty)
    }

    @Test("Feature convenience accessors extract children")
    func featureConvenienceAccessors() {
        let bg = Background(location: Location(line: 2), keyword: "Background", name: "", description: nil, steps: [])
        let s1 = Scenario(location: Location(line: 4), tags: [], keyword: "Scenario", name: "S1", description: nil, steps: [], examples: [])
        let r1 = Rule(location: Location(line: 6), tags: [], keyword: "Rule", name: "R1", description: nil, children: [])

        let feature = Feature(
            location: Location(line: 1),
            tags: [],
            language: "en",
            keyword: "Feature",
            name: "Test",
            description: nil,
            children: [.background(bg), .scenario(s1), .rule(r1)]
        )

        #expect(feature.background != nil)
        #expect(feature.scenarios.count == 1)
        #expect(feature.rules.count == 1)
    }

    // MARK: - GherkinDocument

    @Test("GherkinDocument creation")
    func documentCreation() {
        let doc = GherkinDocument(feature: nil, comments: [])
        #expect(doc.feature == nil)
        #expect(doc.comments.isEmpty)
    }

    // MARK: - Sendable conformance

    @Test("AST types are Sendable")
    func sendableConformance() async {
        let location = Location(line: 1)
        let tag = Tag(location: location, name: "@test")
        let comment = Comment(location: location, text: "# comment")
        let step = Step(
            location: location, keyword: "Given ", keywordType: .context,
            text: "test", docString: nil, dataTable: nil
        )

        // Verify these can cross concurrency boundaries
        await Task {
            _ = location
            _ = tag
            _ = comment
            _ = step
        }.value
    }
}
