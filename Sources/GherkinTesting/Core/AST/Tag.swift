// Tag.swift
// GherkinTesting
//
// Copyright © 2026 Atelier Socle. MIT License.

/// A tag annotation on a Feature, Rule, Scenario, or Examples block.
///
/// Tags begin with `@` in Gherkin source and are used for filtering
/// and organizing test scenarios.
///
/// ```gherkin
/// @smoke @login
/// Scenario: User logs in
/// ```
public struct Tag: Sendable, Equatable, Hashable {
    /// The location of this tag in the source file.
    public let location: Location

    /// The tag name including the `@` prefix (e.g. `"@smoke"`).
    public let name: String

    /// Creates a new tag.
    ///
    /// - Parameters:
    ///   - location: The source location of the tag.
    ///   - name: The full tag name including `@` prefix.
    public init(location: Location, name: String) {
        self.location = location
        self.name = name
    }
}
