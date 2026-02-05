// Step.swift
// GherkinTesting
//
// Copyright © 2026 Atelier Socle. MIT License.

/// A single step within a scenario or background.
///
/// Steps are the fundamental executable units in Gherkin. Each step begins
/// with a keyword (`Given`, `When`, `Then`, `And`, `But`, or `*`) followed
/// by a text description. Steps may optionally include a ``DocString`` or
/// ``DataTable`` argument.
///
/// ```gherkin
/// Given the user "alice" exists
/// When they submit the login form
/// Then they should see "Welcome, Alice!"
/// ```
public struct Step: Sendable, Equatable, Hashable {
    /// The location of this step in the source file.
    public let location: Location

    /// The keyword text exactly as written in the source.
    ///
    /// Includes any trailing whitespace (e.g. `"Given "`, `"When "`, `"And "`).
    public let keyword: String

    /// The semantic type of this step's keyword.
    ///
    /// For `Given`, `When`, and `Then` keywords, this directly corresponds to
    /// ``StepKeywordType/context``, ``StepKeywordType/action``, and
    /// ``StepKeywordType/outcome`` respectively. For `And`, `But`, and `*`
    /// keywords, the type is resolved from the preceding step during parsing.
    public let keywordType: StepKeywordType

    /// The step text after the keyword.
    ///
    /// This is the descriptive text that step definitions are matched against.
    /// For example, in `Given the user "alice" exists`, the text is
    /// `"the user \"alice\" exists"`.
    public let text: String

    /// An optional doc string argument attached to this step.
    ///
    /// A step may have at most one doc string, which provides a multi-line
    /// text argument. This is `nil` when the step has no doc string.
    public let docString: DocString?

    /// An optional data table argument attached to this step.
    ///
    /// A step may have at most one data table, which provides tabular input.
    /// This is `nil` when the step has no data table.
    public let dataTable: DataTable?

    /// Creates a new step.
    ///
    /// - Parameters:
    ///   - location: The source location where the step begins.
    ///   - keyword: The keyword text as written, including trailing whitespace.
    ///   - keywordType: The semantic type of the keyword.
    ///   - text: The step text after the keyword.
    ///   - docString: An optional doc string argument. Pass `nil` if none.
    ///   - dataTable: An optional data table argument. Pass `nil` if none.
    public init(
        location: Location,
        keyword: String,
        keywordType: StepKeywordType,
        text: String,
        docString: DocString?,
        dataTable: DataTable?
    ) {
        self.location = location
        self.keyword = keyword
        self.keywordType = keywordType
        self.text = text
        self.docString = docString
        self.dataTable = dataTable
    }
}
