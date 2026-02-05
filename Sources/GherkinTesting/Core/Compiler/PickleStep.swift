// PickleStep.swift
// GherkinTesting
//
// Copyright © 2026 Atelier Socle. MIT License.

/// An argument attached to a ``PickleStep``.
///
/// A step argument is either a doc string or a data table, with all
/// `<placeholder>` tokens already substituted for Scenario Outline expansions.
@frozen
public enum PickleStepArgument: Sendable, Equatable, Hashable {
    /// A doc string argument with placeholders substituted.
    case docString(DocString)

    /// A data table argument with placeholders substituted in cell values.
    case dataTable(DataTable)
}

/// A single step within a compiled ``Pickle``.
///
/// Pickle steps are the flattened, fully-resolved steps ready for execution.
/// For Scenario Outlines, all `<placeholder>` tokens in the text and arguments
/// have been replaced with the corresponding cell values from the Examples row.
///
/// ```swift
/// for step in pickle.steps {
///     print(step.text) // "the user enters alice and secret123"
/// }
/// ```
public struct PickleStep: Sendable, Equatable, Hashable {
    /// A unique identifier for this step.
    public let id: String

    /// The step text with all placeholders substituted.
    ///
    /// For a regular Scenario, this is the same as the AST step's text.
    /// For a Scenario Outline, `<placeholder>` tokens are replaced with
    /// the corresponding cell value from the current Examples row.
    public let text: String

    /// An optional argument (doc string or data table) with placeholders substituted.
    public let argument: PickleStepArgument?

    /// The AST node IDs this step was derived from.
    ///
    /// Contains the ID of the original ``Step`` AST node, and optionally
    /// the Background step ID when steps were merged from a Background.
    public let astNodeIds: [String]

    /// Creates a new pickle step.
    ///
    /// - Parameters:
    ///   - id: A unique identifier for this step.
    ///   - text: The step text with placeholders substituted.
    ///   - argument: An optional doc string or data table argument.
    ///   - astNodeIds: The AST node IDs for traceability.
    public init(id: String, text: String, argument: PickleStepArgument?, astNodeIds: [String]) {
        self.id = id
        self.text = text
        self.argument = argument
        self.astNodeIds = astNodeIds
    }
}
