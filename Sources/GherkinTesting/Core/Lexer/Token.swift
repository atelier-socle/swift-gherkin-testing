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

/// A token produced by the Gherkin lexer.
///
/// Each token represents a single line (or logical unit) of the Gherkin source.
/// Tokens carry their type, location, the matched keyword (if any), and the
/// remaining text on the line.
public struct Token: Sendable, Equatable, Hashable {
    /// The type of this token.
    public let type: TokenType

    /// The location of this token in the source file.
    public let location: Location

    /// The keyword that was matched (e.g. `"Feature"`, `"Given "`), or `nil` if not applicable.
    public let keyword: String?

    /// The text content of the token (after the keyword, or the full line for non-keyword tokens).
    public let text: String

    /// For table rows, the parsed cell values.
    public let items: [TableCellToken]?

    /// Creates a new token.
    ///
    /// - Parameters:
    ///   - type: The token type.
    ///   - location: The source location.
    ///   - keyword: The matched keyword, if any.
    ///   - text: The text content.
    ///   - items: The parsed table cell tokens, if this is a table row.
    public init(
        type: TokenType,
        location: Location,
        keyword: String? = nil,
        text: String = "",
        items: [TableCellToken]? = nil
    ) {
        self.type = type
        self.location = location
        self.keyword = keyword
        self.text = text
        self.items = items
    }
}

/// A cell within a table row token.
///
/// Represents a single cell value with its column position, produced during
/// lexing of pipe-delimited data table rows.
public struct TableCellToken: Sendable, Equatable, Hashable {
    /// The column position of this cell in the source line.
    public let column: Int

    /// The unescaped value of this cell.
    public let value: String

    /// Creates a new table cell token.
    ///
    /// - Parameters:
    ///   - column: The 1-based column position.
    ///   - value: The cell value.
    public init(column: Int, value: String) {
        self.column = column
        self.value = value
    }
}
