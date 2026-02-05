// Location.swift
// GherkinTesting
//
// Copyright © 2026 Atelier Socle. MIT License.

/// A position within a Gherkin source file.
///
/// Locations are used to track the origin of AST nodes for diagnostics
/// and error reporting. Lines are 1-based; columns are 1-based when known
/// or `0` when unknown.
///
/// ```swift
/// let location = Location(line: 3, column: 5)
/// ```
public struct Location: Sendable, Equatable, Hashable {
    /// The 1-based line number in the source file.
    public let line: Int

    /// The 1-based column number in the source file, or `0` if unknown.
    public let column: Int

    /// Creates a new location.
    ///
    /// - Parameters:
    ///   - line: The 1-based line number.
    ///   - column: The 1-based column number. Defaults to `0` (unknown).
    public init(line: Int, column: Int = 0) {
        self.line = line
        self.column = column
    }
}
