// ExamplePass.swift
// GherkinTesting
//
// Copyright © 2026 Atelier Socle. MIT License.

import Foundation

/// A single row from an Examples table, providing type-safe access to values by column name.
///
/// An `ExamplePass` represents one expansion of a Scenario Outline, holding
/// the column headers and the corresponding cell values from one row.
///
/// ```swift
/// let pass = ExamplePass(headers: ["username", "password"], values: ["alice", "secret"])
/// let user: String = try pass.value(for: "username") // "alice"
/// let count: Int = try pass.value(for: "retries")    // throws ExamplePassError.columnNotFound
/// ```
public struct ExamplePass: Sendable, Equatable, Hashable {
    /// The column names from the Examples table header.
    public let headers: [String]

    /// The cell values from one row, in the same order as ``headers``.
    public let values: [String]

    /// Creates a new example pass.
    ///
    /// - Parameters:
    ///   - headers: The column names from the table header.
    ///   - values: The cell values from one data row.
    /// - Precondition: `headers.count` should equal `values.count`.
    public init(headers: [String], values: [String]) {
        self.headers = headers
        self.values = values
    }

    /// Returns the raw string value for the given column name.
    ///
    /// - Parameter column: The column name (without angle brackets).
    /// - Returns: The cell value for that column.
    /// - Throws: ``ExamplePassError/columnNotFound(_:)`` if the column name is not in the headers.
    public func rawValue(for column: String) throws -> String {
        guard let index = headers.firstIndex(of: column) else {
            throw ExamplePassError.columnNotFound(column)
        }
        guard index < values.count else {
            throw ExamplePassError.columnNotFound(column)
        }
        return values[index]
    }

    /// Returns a typed value for the given column name.
    ///
    /// - Parameter column: The column name (without angle brackets).
    /// - Returns: The cell value converted to the requested type.
    /// - Throws: ``ExamplePassError/columnNotFound(_:)`` if the column is missing,
    ///   or ``ExamplePassError/conversionFailed(_:_:)`` if conversion fails.
    public func value<T: ExampleRepresentable>(for column: String) throws -> T {
        let raw = try rawValue(for: column)
        guard let converted = T.fromExample(raw) else {
            throw ExamplePassError.conversionFailed(column, raw)
        }
        return converted
    }

    /// A dictionary mapping column names to cell values.
    public var dictionary: [String: String] {
        var result: [String: String] = [:]
        result.reserveCapacity(headers.count)
        for (header, val) in zip(headers, values) {
            result[header] = val
        }
        return result
    }
}

/// Errors that can occur when accessing values from an ``ExamplePass``.
public enum ExamplePassError: Error, Sendable, Equatable, LocalizedError {
    /// The requested column name was not found in the table headers.
    case columnNotFound(String)

    /// The cell value could not be converted to the requested type.
    case conversionFailed(String, String)

    /// A localized description of the error.
    public var errorDescription: String? {
        switch self {
        case .columnNotFound(let column):
            return "Column '\(column)' not found in Examples table headers"
        case .conversionFailed(let column, let value):
            return "Cannot convert value '\(value)' in column '\(column)' to requested type"
        }
    }
}
