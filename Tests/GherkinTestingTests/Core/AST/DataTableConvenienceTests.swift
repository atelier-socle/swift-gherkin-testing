// DataTableConvenienceTests.swift
// GherkinTestingTests
//
// Copyright © 2026 Atelier Socle. MIT License.

import Testing

@testable import GherkinTesting

/// Helper to create a TableRow from string values.
private func row(_ values: [String], line: Int = 1) -> TableRow {
    TableRow(
        location: Location(line: line),
        cells: values.map { TableCell(location: Location(line: line), value: $0) }
    )
}

@Suite("DataTable Convenience Extensions")
struct DataTableConvenienceTests {

    // MARK: - DataTable.empty

    @Test("DataTable.empty has no rows")
    func emptyTable() {
        let table = DataTable.empty
        #expect(table.rows.isEmpty)
        #expect(table.headers.isEmpty)
        #expect(table.dataRows.isEmpty)
        #expect(table.asDictionaries.isEmpty)
    }

    // MARK: - headers

    @Test("headers returns first row cell values")
    func headersFromTable() {
        let table = DataTable(
            location: Location(line: 1),
            rows: [
                row(["username", "email"]),
                row(["alice", "alice@example.com"], line: 2),
                row(["bob", "bob@example.com"], line: 3)
            ]
        )
        #expect(table.headers == ["username", "email"])
    }

    @Test("headers on single-row table returns the row values")
    func headersSingleRow() {
        let table = DataTable(
            location: Location(line: 1),
            rows: [row(["a", "b", "c"])]
        )
        #expect(table.headers == ["a", "b", "c"])
    }

    // MARK: - dataRows

    @Test("dataRows returns all rows except first")
    func dataRowsExcludesHeader() {
        let table = DataTable(
            location: Location(line: 1),
            rows: [
                row(["name", "age"]),
                row(["alice", "30"], line: 2),
                row(["bob", "25"], line: 3)
            ]
        )
        #expect(table.dataRows.count == 2)
        #expect(table.dataRows[0].cells[0].value == "alice")
        #expect(table.dataRows[1].cells[0].value == "bob")
    }

    @Test("dataRows on single-row table returns empty")
    func dataRowsSingleRow() {
        let table = DataTable(
            location: Location(line: 1),
            rows: [row(["header"])]
        )
        #expect(table.dataRows.isEmpty)
    }

    @Test("dataRows on empty table returns empty")
    func dataRowsEmptyTable() {
        #expect(DataTable.empty.dataRows.isEmpty)
    }

    // MARK: - asDictionaries

    @Test("asDictionaries maps header keys to cell values")
    func asDictionariesMapping() {
        let table = DataTable(
            location: Location(line: 1),
            rows: [
                row(["name", "age", "role"]),
                row(["alice", "30", "admin"], line: 2),
                row(["bob", "25", "user"], line: 3)
            ]
        )

        let dicts = table.asDictionaries
        #expect(dicts.count == 2)
        #expect(dicts[0] == ["name": "alice", "age": "30", "role": "admin"])
        #expect(dicts[1] == ["name": "bob", "age": "25", "role": "user"])
    }

    @Test("asDictionaries with header only returns empty array")
    func asDictionariesHeaderOnly() {
        let table = DataTable(
            location: Location(line: 1),
            rows: [row(["a", "b"])]
        )
        #expect(table.asDictionaries.isEmpty)
    }

    @Test("asDictionaries with fewer cells than headers omits missing keys")
    func asDictionariesFewerCells() {
        let table = DataTable(
            location: Location(line: 1),
            rows: [
                row(["a", "b", "c"]),
                row(["1", "2"], line: 2)
            ]
        )
        let dicts = table.asDictionaries
        #expect(dicts.count == 1)
        #expect(dicts[0] == ["a": "1", "b": "2"])
    }
}
