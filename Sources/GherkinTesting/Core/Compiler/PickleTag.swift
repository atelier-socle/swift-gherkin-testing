// PickleTag.swift
// GherkinTesting
//
// Copyright © 2026 Atelier Socle. MIT License.

/// A tag on a compiled ``Pickle``.
///
/// Pickle tags are the result of tag inheritance during compilation.
/// They combine tags from the Feature, Rule, Scenario, and Examples
/// levels into a flat list for filtering.
///
/// ```swift
/// for tag in pickle.tags {
///     print(tag.name) // "@smoke"
/// }
/// ```
public struct PickleTag: Sendable, Equatable, Hashable {
    /// The tag name including the `@` prefix (e.g. `"@smoke"`).
    public let name: String

    /// The AST node ID of the original ``Tag`` this was derived from.
    ///
    /// Used for traceability back to the source AST.
    public let astNodeId: String

    /// Creates a new pickle tag.
    ///
    /// - Parameters:
    ///   - name: The tag name including `@` prefix.
    ///   - astNodeId: The ID of the source AST tag node.
    public init(name: String, astNodeId: String) {
        self.name = name
        self.astNodeId = astNodeId
    }
}
