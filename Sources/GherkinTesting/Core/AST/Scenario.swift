// Scenario.swift
// GherkinTesting
//
// Copyright © 2026 Atelier Socle. MIT License.

/// A Scenario or Scenario Outline within a Feature or Rule.
///
/// A Scenario describes a single concrete test case as a sequence of steps.
/// A Scenario Outline is a parameterized template that produces multiple
/// concrete scenarios when expanded against its ``examples`` tables.
///
/// The distinction between the two is determined by the ``examples`` array:
/// - A regular Scenario has an empty ``examples`` array.
/// - A Scenario Outline has one or more ``Examples`` blocks.
///
/// ```gherkin
/// @critical
/// Scenario: Successful login
///   Given the user is on the login page
///   When they enter valid credentials
///   Then they should see the dashboard
///
/// Scenario Outline: Login attempts
///   Given the user is on the login page
///   When they enter "<username>" and "<password>"
///   Then they should see "<result>"
///
///   Examples:
///     | username | password  | result    |
///     | alice    | secret123 | dashboard |
///     | bob      | wrong     | error     |
/// ```
public struct Scenario: Sendable, Equatable, Hashable {
    /// The location of the `Scenario` or `Scenario Outline` keyword in the source file.
    public let location: Location

    /// The tags applied to this scenario.
    ///
    /// Tags from the parent Feature or Rule are inherited during pickle
    /// compilation but are not included in this array, which contains only
    /// the tags declared directly on this scenario.
    public let tags: [Tag]

    /// The keyword used to introduce this scenario.
    ///
    /// Common values include `"Scenario"`, `"Scenario Outline"`,
    /// `"Scenario Template"`, and `"Example"` in English. May be a localized
    /// keyword when using internationalized Gherkin.
    public let keyword: String

    /// The name of the scenario.
    ///
    /// This is the descriptive text following the keyword on the same line
    /// (e.g. `"Successful login"`). This value is an empty string when no
    /// name is provided.
    public let name: String

    /// An optional multiline description following the name line.
    ///
    /// Descriptions provide additional human-readable context for the
    /// scenario. This value is `nil` when no description is present.
    public let description: String?

    /// The ordered list of steps in this scenario.
    ///
    /// Steps define the Given/When/Then actions that make up the test case.
    /// For a Scenario Outline, steps may contain `<placeholder>` tokens that
    /// are substituted during expansion against the ``examples`` tables.
    public let steps: [Step]

    /// The Examples blocks for a Scenario Outline.
    ///
    /// This array is empty for a regular Scenario. For a Scenario Outline,
    /// each ``Examples`` block provides a table of values used to expand
    /// the outline into concrete scenarios.
    public let examples: [Examples]

    /// Creates a new Scenario or Scenario Outline.
    ///
    /// - Parameters:
    ///   - location: The source location of the scenario keyword.
    ///   - tags: The tags declared directly on this scenario.
    ///   - keyword: The keyword text (e.g. `"Scenario"`, `"Scenario Outline"`).
    ///   - name: The scenario name, or an empty string if unnamed.
    ///   - description: An optional multiline description.
    ///   - steps: The ordered list of steps.
    ///   - examples: The Examples blocks for outline expansion. Pass an empty
    ///     array for regular scenarios.
    public init(
        location: Location,
        tags: [Tag],
        keyword: String,
        name: String,
        description: String?,
        steps: [Step],
        examples: [Examples]
    ) {
        self.location = location
        self.tags = tags
        self.keyword = keyword
        self.name = name
        self.description = description
        self.steps = steps
        self.examples = examples
    }
}
