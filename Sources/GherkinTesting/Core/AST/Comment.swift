// Comment.swift
// GherkinTesting
//
// Copyright © 2026 Atelier Socle. MIT License.

/// A comment line in a Gherkin source file.
///
/// Comments start with `#` and extend to the end of the line.
/// They are preserved in the AST but have no semantic meaning.
///
/// ```gherkin
/// # This is a comment
/// Feature: Login
/// ```
public struct Comment: Sendable, Equatable, Hashable {
    /// The location of this comment in the source file.
    public let location: Location

    /// The full text of the comment line, including the `#` prefix.
    public let text: String

    /// Creates a new comment.
    ///
    /// - Parameters:
    ///   - location: The source location where the comment begins.
    ///   - text: The full comment text including the `#` prefix.
    public init(location: Location, text: String) {
        self.location = location
        self.text = text
    }
}
