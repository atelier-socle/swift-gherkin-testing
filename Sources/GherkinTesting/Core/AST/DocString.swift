// DocString.swift
// GherkinTesting
//
// Copyright © 2026 Atelier Socle. MIT License.

/// A multi-line string argument attached to a step.
///
/// Doc strings are delimited by triple quotes (`"""`) or triple backticks
/// (`` ``` ``). They allow passing large blocks of text, JSON, XML, or other
/// content as a step argument.
///
/// ```gherkin
/// Given the following JSON payload:
///   """json
///   {
///     "username": "alice",
///     "role": "admin"
///   }
///   """
/// ```
public struct DocString: Sendable, Equatable, Hashable {
    /// The location of the opening delimiter in the source file.
    public let location: Location

    /// An optional media type hint following the opening delimiter.
    ///
    /// For example, `"json"` when the doc string opens with `"""json` or
    /// `` ```json ``. This value is `nil` when no media type is specified.
    public let mediaType: String?

    /// The content between the opening and closing delimiters.
    ///
    /// Leading indentation matching the delimiter's indentation is stripped.
    /// The content does not include the delimiters themselves.
    public let content: String

    /// The delimiter used to open and close this doc string.
    ///
    /// Either `"\"\"\""` (triple quotes) or `` ``` `` (triple backticks).
    public let delimiter: String

    /// Creates a new doc string.
    ///
    /// - Parameters:
    ///   - location: The source location of the opening delimiter.
    ///   - mediaType: An optional media type hint (e.g. `"json"`, `"xml"`).
    ///   - content: The text content between the delimiters.
    ///   - delimiter: The delimiter used: `"\"\"\""` or `` ``` ``.
    public init(location: Location, mediaType: String?, content: String, delimiter: String) {
        self.location = location
        self.mediaType = mediaType
        self.content = content
        self.delimiter = delimiter
    }
}
