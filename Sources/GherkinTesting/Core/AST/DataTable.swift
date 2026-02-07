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

    /// An empty data table with no rows.
    ///
    /// Used as a default when a step handler declares a `DataTable` parameter
    /// but the pickle step has no attached argument.
    public static let empty = DataTable(location: Location(line: 0, column: 0), rows: [])

    /// The first row's cell values, typically used as column headers.
    ///
    /// Returns an empty array if the table has no rows.
    public var headers: [String] {
        rows.first?.cells.map(\.value) ?? []
    }

    /// All rows except the first (header) row.
    ///
    /// Returns an empty array if the table has zero or one row.
    public var dataRows: [TableRow] {
        rows.count > 1 ? Array(rows.dropFirst()) : []
    }

    /// Converts the table to an array of dictionaries keyed by header values.
    ///
    /// Each dictionary maps header names to the corresponding cell values
    /// in that row. If a row has fewer cells than headers, missing keys
    /// are omitted.
    ///
    /// ```swift
    /// // Given a table:
    /// //   | name  | age |
    /// //   | alice | 30  |
    /// //   | bob   | 25  |
    /// // asDictionaries → [["name": "alice", "age": "30"], ["name": "bob", "age": "25"]]
    /// ```
    public var asDictionaries: [[String: String]] {
        guard let headerRow = rows.first else { return [] }
        let keys = headerRow.cells.map(\.value)
        return dataRows.map { row in
            var dict: [String: String] = [:]
            for (i, cell) in row.cells.enumerated() where i < keys.count {
                dict[keys[i]] = cell.value
            }
            return dict
        }
    }
}
