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

/// An error that occurs during parsing of a Gherkin source file.
///
/// Parser errors include the source location where the error was detected
/// and a human-readable description of the problem.
///
/// ```swift
/// do {
///     let document = try GherkinParser().parse(source: text)
/// } catch let error as ParserError {
///     print("Error at line \(error.location.line): \(error.message)")
/// }
/// ```
public struct ParserError: Error, Sendable, Equatable, Hashable, LocalizedError {
    /// The location in the source file where the error was detected.
    public let location: Location

    /// A human-readable description of the parsing error.
    public let message: String

    /// Creates a new parser error.
    ///
    /// - Parameters:
    ///   - location: The source location where the error was detected.
    ///   - message: A descriptive error message.
    public init(location: Location, message: String) {
        self.location = location
        self.message = message
    }

    /// A localized description of the error.
    public var errorDescription: String? {
        "(\(location.line):\(location.column)): \(message)"
    }

    // MARK: - Factory Methods

    /// Creates an error for an unexpected token.
    ///
    /// - Parameters:
    ///   - token: The unexpected token.
    ///   - expected: A description of what was expected.
    /// - Returns: A ``ParserError`` describing the unexpected token.
    public static func unexpectedToken(_ token: Token, expected: String) -> ParserError {
        ParserError(
            location: token.location,
            message: "Unexpected token '\(token.type)': expected \(expected)"
        )
    }

    /// Creates an error for an unexpected end of file.
    ///
    /// - Parameters:
    ///   - location: The location at end of file.
    ///   - expected: A description of what was expected.
    /// - Returns: A ``ParserError`` describing the premature EOF.
    public static func unexpectedEOF(at location: Location, expected: String) -> ParserError {
        ParserError(
            location: location,
            message: "Unexpected end of file: expected \(expected)"
        )
    }

    /// Creates an error for inconsistent cell count in a table.
    ///
    /// - Parameter location: The location of the row with inconsistent cell count.
    /// - Returns: A ``ParserError`` for the inconsistent table.
    public static func inconsistentTableCellCount(at location: Location) -> ParserError {
        ParserError(
            location: location,
            message: "Inconsistent cell count in data table row"
        )
    }

    /// Creates an error for a duplicate Background definition.
    ///
    /// - Parameter location: The location of the duplicate Background.
    /// - Returns: A ``ParserError`` for the duplicate.
    public static func duplicateBackground(at location: Location) -> ParserError {
        ParserError(
            location: location,
            message: "Only one Background is allowed per Feature or Rule"
        )
    }
}
