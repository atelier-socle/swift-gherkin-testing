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

/// Utilities for substituting `<placeholder>` tokens in Gherkin text.
///
/// Scenario Outlines contain angle-bracket placeholders (e.g. `<username>`)
/// that must be replaced with concrete values from the Examples table during
/// pickle compilation. This enum provides the substitution logic.
///
/// ```swift
/// let text = "the user enters <username> and <password>"
/// let values = ["username": "alice", "password": "secret"]
/// let result = ExampleExpansion.substitute(in: text, values: values)
/// // "the user enters alice and secret"
/// ```
public enum ExampleExpansion: Sendable {

    /// Substitutes all `<placeholder>` tokens in the given text.
    ///
    /// Each occurrence of `<key>` is replaced with the corresponding value
    /// from the `values` dictionary. Placeholders with no matching key are
    /// left as-is.
    ///
    /// - Parameters:
    ///   - text: The text containing `<placeholder>` tokens.
    ///   - values: A dictionary mapping placeholder names to replacement values.
    /// - Returns: The text with all matching placeholders replaced.
    public static func substitute(in text: String, values: [String: String]) -> String {
        guard text.contains("<") else { return text }

        var result = text
        for (key, value) in values {
            let placeholder = "<\(key)>"
            result = result.replacingOccurrences(of: placeholder, with: value)
        }
        return result
    }

    /// Substitutes placeholders in a ``DocString``, returning a new instance.
    ///
    /// Replaces `<placeholder>` tokens in the doc string's ``DocString/content``.
    /// The media type and delimiter are preserved unchanged.
    ///
    /// - Parameters:
    ///   - docString: The original doc string with placeholders.
    ///   - values: A dictionary mapping placeholder names to replacement values.
    /// - Returns: A new ``DocString`` with placeholders substituted in the content.
    public static func substitute(in docString: DocString, values: [String: String]) -> DocString {
        DocString(
            location: docString.location,
            mediaType: docString.mediaType,
            content: substitute(in: docString.content, values: values),
            delimiter: docString.delimiter
        )
    }

    /// Substitutes placeholders in a ``DataTable``, returning a new instance.
    ///
    /// Replaces `<placeholder>` tokens in every cell value of every row.
    ///
    /// - Parameters:
    ///   - dataTable: The original data table with placeholders.
    ///   - values: A dictionary mapping placeholder names to replacement values.
    /// - Returns: A new ``DataTable`` with placeholders substituted in all cells.
    public static func substitute(in dataTable: DataTable, values: [String: String]) -> DataTable {
        let newRows = dataTable.rows.map { row in
            let newCells = row.cells.map { cell in
                TableCell(
                    location: cell.location,
                    value: substitute(in: cell.value, values: values)
                )
            }
            return TableRow(location: row.location, cells: newCells)
        }
        return DataTable(location: dataTable.location, rows: newRows)
    }
}
