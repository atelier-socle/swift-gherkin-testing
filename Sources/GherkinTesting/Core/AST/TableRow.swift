// TableRow.swift
// GherkinTesting
//
// Copyright © 2026 Atelier Socle. MIT License.

/// A single cell within a table row.
///
/// Table cells contain the text value between pipe (`|`) delimiters
/// in a Gherkin data table or examples table.
///
/// ```gherkin
/// | username | password |
/// ```
///
/// In this example, `"username"` and `"password"` are each a `TableCell`.
public struct TableCell: Sendable, Equatable, Hashable {
    /// The location of this cell's value in the source file.
    public let location: Location

    /// The text content of the cell, with leading and trailing whitespace trimmed.
    public let value: String

    /// Creates a new table cell.
    ///
    /// - Parameters:
    ///   - location: The source location of the cell value.
    ///   - value: The trimmed text content of the cell.
    public init(location: Location, value: String) {
        self.location = location
        self.value = value
    }
}

/// A row of cells in a data table or examples table.
///
/// Each row represents a pipe-delimited line in a Gherkin table structure.
///
/// ```gherkin
/// | alice | secret123 |
/// | bob   | pass456   |
/// ```
///
/// Each line above is a single `TableRow` containing two ``TableCell`` values.
public struct TableRow: Sendable, Equatable, Hashable {
    /// The location of this row in the source file.
    public let location: Location

    /// The ordered list of cells in this row.
    public let cells: [TableCell]

    /// Creates a new table row.
    ///
    /// - Parameters:
    ///   - location: The source location where the row begins.
    ///   - cells: The ordered list of cells in the row.
    public init(location: Location, cells: [TableCell]) {
        self.location = location
        self.cells = cells
    }
}
