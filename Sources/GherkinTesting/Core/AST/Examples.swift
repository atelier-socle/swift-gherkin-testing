// Examples.swift
// GherkinTesting
//
// Copyright © 2026 Atelier Socle. MIT License.

/// An Examples (or Scenarios) table attached to a Scenario Outline.
///
/// Examples blocks provide the data rows used to expand a Scenario Outline
/// into concrete scenarios. Each row in the table body produces one scenario
/// by substituting its values into the outline's `<placeholder>` tokens.
///
/// A Scenario Outline can have multiple Examples blocks, optionally with
/// different tags, allowing subsets of data to be filtered independently.
///
/// ```gherkin
/// Scenario Outline: Eating cucumbers
///   Given there are <start> cucumbers
///   When I eat <eat> cucumbers
///   Then I should have <left> cucumbers
///
///   Examples: Few cucumbers
///     | start | eat | left |
///     |    12 |   5 |    7 |
///     |    20 |   5 |   15 |
///
///   @slow
///   Examples: Many cucumbers
///     | start | eat | left |
///     |  1000 | 500 |  500 |
/// ```
public struct Examples: Sendable, Equatable, Hashable {
    /// The location of the `Examples` keyword in the source file.
    public let location: Location

    /// The tags applied to this Examples block.
    ///
    /// Tags on an Examples block are combined with the parent Scenario Outline's
    /// tags when evaluating tag filter expressions.
    public let tags: [Tag]

    /// The keyword used to introduce this block.
    ///
    /// Typically `"Examples"` or `"Scenarios"` in English, but may be a
    /// localized keyword when using internationalized Gherkin.
    public let keyword: String

    /// The name following the keyword, if any.
    ///
    /// Examples blocks may have a descriptive name (e.g. `"Few cucumbers"`).
    /// This value is `nil` when no name is provided.
    public let name: String?

    /// An optional multiline description following the name line.
    ///
    /// Descriptions provide additional human-readable context for the
    /// Examples block. This value is `nil` when no description is present.
    public let description: String?

    /// The header row defining column names for the table.
    ///
    /// The header contains the placeholder names (without angle brackets)
    /// that correspond to `<placeholder>` tokens in the parent Scenario Outline.
    /// This value is `nil` when the Examples block has no table at all,
    /// which represents an empty or malformed Examples section.
    public let tableHeader: TableRow?

    /// The data rows of the table.
    ///
    /// Each row provides one set of substitution values for expanding the
    /// parent Scenario Outline into a concrete scenario. The number of cells
    /// in each row must match the number of cells in ``tableHeader``.
    public let tableBody: [TableRow]

    /// Creates a new Examples block.
    ///
    /// - Parameters:
    ///   - location: The source location of the `Examples` keyword.
    ///   - tags: The tags applied to this Examples block.
    ///   - keyword: The keyword text (e.g. `"Examples"`, `"Scenarios"`).
    ///   - name: The name following the keyword, or `nil` if unnamed.
    ///   - description: An optional multiline description.
    ///   - tableHeader: The header row defining column names, or `nil` if absent.
    ///   - tableBody: The data rows for scenario expansion.
    public init(
        location: Location,
        tags: [Tag],
        keyword: String,
        name: String?,
        description: String?,
        tableHeader: TableRow?,
        tableBody: [TableRow]
    ) {
        self.location = location
        self.tags = tags
        self.keyword = keyword
        self.name = name
        self.description = description
        self.tableHeader = tableHeader
        self.tableBody = tableBody
    }
}
