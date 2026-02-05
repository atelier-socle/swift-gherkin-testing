// Pickle.swift
// GherkinTesting
//
// Copyright © 2026 Atelier Socle. MIT License.

/// A compiled, executable test case derived from a Gherkin AST.
///
/// A Pickle represents a single test case ready for execution. It is produced
/// by the ``PickleCompiler`` from the AST, with:
/// - Background steps merged in the correct order
/// - Scenario Outline placeholders substituted
/// - Tags inherited from Feature, Rule, Scenario, and Examples levels
///
/// ```swift
/// let compiler = PickleCompiler()
/// let pickles = compiler.compile(document)
/// for pickle in pickles {
///     print("\(pickle.name): \(pickle.steps.count) steps, \(pickle.tags.count) tags")
/// }
/// ```
public struct Pickle: Sendable, Equatable, Hashable {
    /// A unique identifier for this pickle.
    ///
    /// Generated deterministically from the source location and examples row index
    /// to ensure stable IDs across compilations.
    public let id: String

    /// The source file URI this pickle was compiled from.
    public let uri: String

    /// The name of this test case.
    ///
    /// For a regular Scenario, this is the scenario name. For a Scenario Outline,
    /// this is the scenario name with `<placeholder>` tokens replaced by the
    /// values from the current Examples row.
    public let name: String

    /// The language code of the source Feature.
    public let language: String

    /// The combined tags from all levels (Feature, Rule, Scenario, Examples).
    ///
    /// Tags are inherited downward: a Feature tag applies to all its children,
    /// a Rule tag applies to all Scenarios within the Rule, etc.
    public let tags: [PickleTag]

    /// The ordered steps for this test case.
    ///
    /// Includes Background steps (Feature-level first, then Rule-level) followed
    /// by the Scenario's own steps, all with placeholders substituted.
    public let steps: [PickleStep]

    /// The AST node IDs this pickle was derived from.
    ///
    /// For traceability back to the original Scenario and Examples row.
    public let astNodeIds: [String]

    /// Creates a new pickle.
    ///
    /// - Parameters:
    ///   - id: A unique identifier.
    ///   - uri: The source file URI.
    ///   - name: The test case name.
    ///   - language: The source Feature's language code.
    ///   - tags: The combined inherited tags.
    ///   - steps: The ordered steps for execution.
    ///   - astNodeIds: The AST node IDs for traceability.
    public init(
        id: String,
        uri: String,
        name: String,
        language: String,
        tags: [PickleTag],
        steps: [PickleStep],
        astNodeIds: [String]
    ) {
        self.id = id
        self.uri = uri
        self.name = name
        self.language = language
        self.tags = tags
        self.steps = steps
        self.astNodeIds = astNodeIds
    }
}
