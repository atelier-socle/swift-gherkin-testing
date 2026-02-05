// ExampleExpansionTests.swift
// GherkinTestingTests
//
// Copyright © 2026 Atelier Socle. MIT License.

import Testing
@testable import GherkinTesting

@Suite("ExampleExpansion Tests")
struct ExampleExpansionTests {

    // MARK: - Text Substitution

    @Test("Substitutes single placeholder")
    func singlePlaceholder() {
        let result = ExampleExpansion.substitute(
            in: "the user <name>",
            values: ["name": "Alice"]
        )
        #expect(result == "the user Alice")
    }

    @Test("Substitutes multiple placeholders")
    func multiplePlaceholders() {
        let result = ExampleExpansion.substitute(
            in: "<user> enters <password>",
            values: ["user": "alice", "password": "secret"]
        )
        #expect(result == "alice enters secret")
    }

    @Test("Leaves unmatched placeholders as-is")
    func unmatchedPlaceholder() {
        let result = ExampleExpansion.substitute(
            in: "<missing> and <present>",
            values: ["present": "value"]
        )
        #expect(result == "<missing> and value")
    }

    @Test("Returns text unchanged when no angle brackets")
    func noPlaceholders() {
        let result = ExampleExpansion.substitute(
            in: "no placeholders here",
            values: ["key": "value"]
        )
        #expect(result == "no placeholders here")
    }

    @Test("Handles empty values dictionary")
    func emptyValues() {
        let result = ExampleExpansion.substitute(
            in: "<x> and <y>",
            values: [:]
        )
        #expect(result == "<x> and <y>")
    }

    @Test("Handles empty text")
    func emptyText() {
        let result = ExampleExpansion.substitute(
            in: "",
            values: ["x": "1"]
        )
        #expect(result == "")
    }

    @Test("Substitutes same placeholder multiple times")
    func repeatedPlaceholder() {
        let result = ExampleExpansion.substitute(
            in: "<x> and <x> again",
            values: ["x": "val"]
        )
        #expect(result == "val and val again")
    }

    // MARK: - DocString Substitution

    @Test("Substitutes placeholders in DocString content")
    func docStringSubstitution() {
        let ds = DocString(
            location: Location(line: 1),
            mediaType: "json",
            content: "Hello <name>!",
            delimiter: "\"\"\""
        )
        let result = ExampleExpansion.substitute(in: ds, values: ["name": "Alice"])
        #expect(result.content == "Hello Alice!")
        #expect(result.mediaType == "json")
        #expect(result.delimiter == "\"\"\"")
        #expect(result.location.line == 1)
    }

    @Test("DocString with no placeholders unchanged")
    func docStringNoPlaceholders() {
        let ds = DocString(
            location: Location(line: 5),
            mediaType: nil,
            content: "static content",
            delimiter: "```"
        )
        let result = ExampleExpansion.substitute(in: ds, values: ["x": "1"])
        #expect(result.content == "static content")
    }

    // MARK: - DataTable Substitution

    @Test("Substitutes placeholders in DataTable cells")
    func dataTableSubstitution() {
        let dt = DataTable(location: Location(line: 1), rows: [
            TableRow(location: Location(line: 1), cells: [
                TableCell(location: Location(line: 1), value: "header"),
            ]),
            TableRow(location: Location(line: 2), cells: [
                TableCell(location: Location(line: 2), value: "<name>"),
            ]),
        ])
        let result = ExampleExpansion.substitute(in: dt, values: ["name": "Alice"])
        #expect(result.rows[0].cells[0].value == "header")
        #expect(result.rows[1].cells[0].value == "Alice")
    }

    @Test("DataTable with no placeholders unchanged")
    func dataTableNoPlaceholders() {
        let dt = DataTable(location: Location(line: 1), rows: [
            TableRow(location: Location(line: 1), cells: [
                TableCell(location: Location(line: 1), value: "static"),
            ]),
        ])
        let result = ExampleExpansion.substitute(in: dt, values: ["x": "1"])
        #expect(result.rows[0].cells[0].value == "static")
    }

    @Test("DataTable substitutes in multiple cells")
    func dataTableMultipleCells() {
        let dt = DataTable(location: Location(line: 1), rows: [
            TableRow(location: Location(line: 1), cells: [
                TableCell(location: Location(line: 1), value: "<a>"),
                TableCell(location: Location(line: 1), value: "<b>"),
            ]),
        ])
        let result = ExampleExpansion.substitute(in: dt, values: ["a": "1", "b": "2"])
        #expect(result.rows[0].cells[0].value == "1")
        #expect(result.rows[0].cells[1].value == "2")
    }
}
