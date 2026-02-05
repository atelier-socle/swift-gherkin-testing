// GherkinDocument.swift
// GherkinTesting
//
// Copyright © 2026 Atelier Socle. MIT License.

/// The root node of a Gherkin AST representing an entire `.feature` file.
///
/// A `GherkinDocument` is the top-level container produced by the parser.
/// It holds an optional ``Feature`` (since a file could be empty or contain
/// only comments) and all ``Comment`` nodes found anywhere in the source.
///
/// ```swift
/// let parser = GherkinParser()
/// let document = try parser.parse(source: featureText)
///
/// if let feature = document.feature {
///     print("Feature: \(feature.name)")
/// }
///
/// for comment in document.comments {
///     print("Comment at line \(comment.location.line): \(comment.text)")
/// }
/// ```
public struct GherkinDocument: Sendable, Equatable, Hashable {
    /// The Feature defined in this document, if any.
    ///
    /// This value is `nil` when the source file is empty, contains only
    /// comments, or does not include a `Feature` keyword. A valid `.feature`
    /// file typically contains exactly one Feature.
    public let feature: Feature?

    /// All comments found in the source file.
    ///
    /// Comments are preserved in source order and include the `#` prefix.
    /// They carry no semantic meaning but are retained in the AST for
    /// round-trip fidelity and tooling support.
    public let comments: [Comment]

    /// Creates a new Gherkin document.
    ///
    /// - Parameters:
    ///   - feature: The Feature defined in the document, or `nil` if absent.
    ///   - comments: All comments found in the source file.
    public init(feature: Feature?, comments: [Comment]) {
        self.feature = feature
        self.comments = comments
    }
}
