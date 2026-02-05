// DataTable.swift
// GherkinTesting
//
// Copyright © 2026 Atelier Socle. MIT License.

/// A table of data attached to a step as an argument.
///
/// Data tables provide structured tabular input for steps. Each row contains
/// the same number of cells, delimited by pipe (`|`) characters.
///
/// ```gherkin
/// Given the following users exist:
///   | username | email            |
///   | alice    | alice@example.com |
///   | bob      | bob@example.com   |
/// ```
///
/// The first row is typically treated as a header row, though this
/// interpretation is left to the step definition.
public struct DataTable: Sendable, Equatable, Hashable {
    /// The location of the first row of the table in the source file.
    public let location: Location

    /// The ordered list of rows in the table.
    ///
    /// All rows are expected to have the same number of cells.
    public let rows: [TableRow]

    /// Creates a new data table.
    ///
    /// - Parameters:
    ///   - location: The source location where the table begins.
    ///   - rows: The ordered list of table rows.
    public init(location: Location, rows: [TableRow]) {
        self.location = location
        self.rows = rows
    }
}
