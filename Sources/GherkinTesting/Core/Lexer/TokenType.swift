// TokenType.swift
// GherkinTesting
//
// Copyright © 2026 Atelier Socle. MIT License.

/// The type of a lexer token produced by the Gherkin lexer.
///
/// Each token represents a syntactic element found during line-by-line
/// tokenization of a `.feature` file.
@frozen
public enum TokenType: Sendable, Equatable, Hashable {
    /// A `Feature:` keyword line (or localized equivalent).
    case feature

    /// A `Rule:` keyword line (or localized equivalent).
    case rule

    /// A `Background:` keyword line (or localized equivalent).
    case background

    /// A `Scenario:` or `Example:` keyword line (or localized equivalent).
    case scenario

    /// A `Scenario Outline:` or `Scenario Template:` keyword line (or localized equivalent).
    case scenarioOutline

    /// An `Examples:` or `Scenarios:` keyword line (or localized equivalent).
    case examples

    /// A step keyword line (`Given`, `When`, `Then`, `And`, `But`, or `*`).
    case step

    /// A doc string delimiter line (`"""` or `` ``` ``).
    case docString

    /// A line of content within a doc string block.
    case docStringContent

    /// A data table row line (pipe-delimited cells).
    case tableRow

    /// A tag line containing one or more `@tag` annotations.
    case tagLine

    /// A comment line starting with `#`.
    case comment

    /// A `# language:` directive.
    case language

    /// A blank or whitespace-only line.
    case empty

    /// A non-empty line that is not a recognized keyword — typically a description line.
    case other

    /// End of input.
    case eof
}
