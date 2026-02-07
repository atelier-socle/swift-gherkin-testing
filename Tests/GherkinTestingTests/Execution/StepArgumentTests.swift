// StepArgumentTests.swift
// GherkinTestingTests
//
// Copyright © 2026 Atelier Socle. MIT License.

import Testing

@testable import GherkinTesting

@Suite("StepArgument")
struct StepArgumentTests {

    // MARK: - Init from PickleStepArgument

    @Test("Init from nil returns nil")
    func initFromNil() {
        let result = StepArgument(from: nil)
        #expect(result == nil)
    }

    @Test("Init from DataTable pickle argument creates .dataTable")
    func initFromDataTable() {
        let table = DataTable(
            location: Location(line: 1, column: 1),
            rows: [
                TableRow(
                    location: Location(line: 1),
                    cells: [
                        TableCell(location: Location(line: 1), value: "name")
                    ])
            ]
        )
        let pickleArg = PickleStepArgument.dataTable(table)
        let result = StepArgument(from: pickleArg)

        #expect(result == .dataTable(table))
    }

    @Test("Init from DocString pickle argument creates .docString with content")
    func initFromDocString() {
        let doc = DocString(
            location: Location(line: 1, column: 1),
            mediaType: "json",
            content: "{\"key\": \"value\"}",
            delimiter: "\"\"\""
        )
        let pickleArg = PickleStepArgument.docString(doc)
        let result = StepArgument(from: pickleArg)

        #expect(result == .docString("{\"key\": \"value\"}"))
    }

    // MARK: - Accessor Properties

    @Test("dataTable accessor returns table for .dataTable case")
    func dataTableAccessor() {
        let table = DataTable.empty
        let arg = StepArgument.dataTable(table)

        #expect(arg.dataTable == table)
        #expect(arg.docString == nil)
    }

    @Test("docString accessor returns content for .docString case")
    func docStringAccessor() {
        let arg = StepArgument.docString("hello world")

        #expect(arg.docString == "hello world")
        #expect(arg.dataTable == nil)
    }

    // MARK: - Equatable

    @Test("Two equal DataTable arguments are equal")
    func dataTableEquality() {
        let table = DataTable.empty
        #expect(StepArgument.dataTable(table) == StepArgument.dataTable(table))
    }

    @Test("Two equal DocString arguments are equal")
    func docStringEquality() {
        #expect(StepArgument.docString("abc") == StepArgument.docString("abc"))
    }

    @Test("DataTable and DocString arguments are not equal")
    func dataTableNotEqualDocString() {
        #expect(StepArgument.dataTable(.empty) != StepArgument.docString(""))
    }
}
