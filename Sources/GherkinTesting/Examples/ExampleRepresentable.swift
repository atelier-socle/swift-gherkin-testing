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

/// A type that can be initialized from a Gherkin Examples table cell value.
///
/// Conform to this protocol to enable type-safe extraction of values from
/// Scenario Outline Examples rows. Built-in conformances are provided for
/// `String`, `Int`, `Double`, `Bool`, and their `Optional` wrappers.
///
/// ```swift
/// let pass = ExamplePass(headers: ["count"], values: ["42"])
/// let count: Int = try pass.value(for: "count")
/// ```
public protocol ExampleRepresentable: Sendable {
    /// Initializes a value from an Examples table cell string.
    ///
    /// - Parameter cellValue: The raw string value from the Examples table cell.
    /// - Returns: The converted value, or `nil` if conversion fails.
    static func fromExample(_ cellValue: String) -> Self?
}

extension String: ExampleRepresentable {
    /// Strings are always representable — returns the cell value as-is.
    public static func fromExample(_ cellValue: String) -> String? {
        cellValue
    }
}

extension Int: ExampleRepresentable {
    /// Converts the cell value to an `Int`.
    ///
    /// - Parameter cellValue: A string representing an integer (e.g. `"42"`, `"-7"`).
    /// - Returns: The integer value, or `nil` if the string is not a valid integer.
    public static func fromExample(_ cellValue: String) -> Int? {
        Int(cellValue)
    }
}

extension Double: ExampleRepresentable {
    /// Converts the cell value to a `Double`.
    ///
    /// - Parameter cellValue: A string representing a floating-point number (e.g. `"3.14"`).
    /// - Returns: The double value, or `nil` if the string is not a valid number.
    public static func fromExample(_ cellValue: String) -> Double? {
        Double(cellValue)
    }
}

extension Bool: ExampleRepresentable {
    /// Converts the cell value to a `Bool`.
    ///
    /// Recognized true values: `"true"`, `"yes"`, `"1"` (case-insensitive).
    /// Recognized false values: `"false"`, `"no"`, `"0"` (case-insensitive).
    ///
    /// - Parameter cellValue: A string representing a boolean.
    /// - Returns: The boolean value, or `nil` if not recognized.
    public static func fromExample(_ cellValue: String) -> Bool? {
        switch cellValue.lowercased() {
        case "true", "yes", "1":
            return true
        case "false", "no", "0":
            return false
        default:
            return nil
        }
    }
}

extension Optional: ExampleRepresentable where Wrapped: ExampleRepresentable {
    /// Converts the cell value to an optional of the wrapped type.
    ///
    /// Empty strings are treated as `nil`. Non-empty strings are converted
    /// using the wrapped type's `fromExample(_:)` method.
    ///
    /// - Parameter cellValue: The raw cell value string.
    /// - Returns: `.some(value)` if conversion succeeds, `.some(nil)` for empty strings,
    ///   or `nil` if conversion of a non-empty string fails.
    public static func fromExample(_ cellValue: String) -> Wrapped?? {
        if cellValue.isEmpty {
            return .some(nil)
        }
        guard let value = Wrapped.fromExample(cellValue) else {
            return nil
        }
        return .some(value)
    }
}
