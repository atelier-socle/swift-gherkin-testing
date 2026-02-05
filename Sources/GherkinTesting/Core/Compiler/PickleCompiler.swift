// PickleCompiler.swift
// GherkinTesting
//
// Copyright © 2026 Atelier Socle. MIT License.

/// Compiles a ``GherkinDocument`` AST into an array of ``Pickle`` test cases.
///
/// The compiler flattens the hierarchical AST structure into a flat list of
/// executable test cases, handling:
/// - Background step merging (Feature-level then Rule-level)
/// - Scenario Outline expansion with `<placeholder>` substitution
/// - Tag inheritance from Feature → Rule → Scenario → Examples
///
/// For large Scenario Outlines (100K+ rows), use ``compileSequence(_:uri:)``
/// to lazily yield one Pickle at a time without materializing all Pickles
/// in memory simultaneously.
///
/// ```swift
/// let compiler = PickleCompiler()
/// let pickles = compiler.compile(document)
/// // Or for lazy iteration:
/// for pickle in compiler.compileSequence(document) {
///     execute(pickle)
/// }
/// ```
public struct PickleCompiler: Sendable {

    /// Creates a new pickle compiler.
    public init() {}

    /// Compiles a ``GherkinDocument`` into an array of ``Pickle`` test cases.
    ///
    /// This materializes all pickles in memory. For very large Scenario Outlines,
    /// prefer ``compileSequence(_:uri:)`` to avoid excessive memory usage.
    ///
    /// - Parameters:
    ///   - document: The parsed Gherkin document.
    ///   - uri: An optional source file URI for traceability. Defaults to empty string.
    /// - Returns: An array of compiled pickles.
    public func compile(_ document: GherkinDocument, uri: String = "") -> [Pickle] {
        Array(compileSequence(document, uri: uri))
    }

    /// Compiles a ``GherkinDocument`` into a lazy sequence of ``Pickle`` test cases.
    ///
    /// Each pickle is created on demand as the sequence is iterated, then released
    /// when no longer referenced. This enables processing of Scenario Outlines with
    /// 100K–1M Examples rows without exhausting memory.
    ///
    /// - Parameters:
    ///   - document: The parsed Gherkin document.
    ///   - uri: An optional source file URI for traceability. Defaults to empty string.
    /// - Returns: A sequence that yields one ``Pickle`` per iteration.
    public func compileSequence(_ document: GherkinDocument, uri: String = "") -> PickleSequence {
        PickleSequence(document: document, uri: uri)
    }
}

/// A lazy sequence that yields ``Pickle`` test cases one at a time.
///
/// This sequence avoids materializing all pickles in memory simultaneously,
/// enabling efficient processing of very large Scenario Outlines.
public struct PickleSequence: Sequence, Sendable {
    let document: GherkinDocument
    let uri: String

    /// Creates a new pickle sequence.
    ///
    /// - Parameters:
    ///   - document: The parsed Gherkin document.
    ///   - uri: The source file URI.
    init(document: GherkinDocument, uri: String) {
        self.document = document
        self.uri = uri
    }

    public func makeIterator() -> PickleIterator {
        PickleIterator(document: document, uri: uri)
    }
}

/// An iterator that yields ``Pickle`` values from a ``GherkinDocument``.
public struct PickleIterator: IteratorProtocol, Sendable {
    public typealias Element = Pickle

    private let document: GherkinDocument
    private let uri: String
    private let feature: Feature?
    private let language: String
    private let featureTags: [Tag]
    private let outlineKeywords: Set<String>

    /// Flat list of work items to process.
    private var workItems: [WorkItem]
    private var workIndex: Int = 0
    private var idCounter: Int = 0

    init(document: GherkinDocument, uri: String) {
        self.document = document
        self.uri = uri
        self.feature = document.feature
        let langCode = document.feature?.language ?? "en"
        self.language = langCode
        self.featureTags = document.feature?.tags ?? []

        let lang = LanguageRegistry.language(for: langCode)
        self.outlineKeywords = Set(lang?.scenarioOutline ?? ["Scenario Outline", "Scenario Template"])

        var items: [WorkItem] = []
        if let feature = document.feature {
            var featureBackground: Background?

            for child in feature.children {
                switch child {
                case .background(let bg):
                    featureBackground = bg
                case .scenario(let scenario):
                    items.append(WorkItem(
                        scenario: scenario,
                        featureBackground: featureBackground,
                        ruleBackground: nil,
                        ruleTags: []
                    ))
                case .rule(let rule):
                    var ruleBackground: Background?
                    for ruleChild in rule.children {
                        switch ruleChild {
                        case .background(let bg):
                            ruleBackground = bg
                        case .scenario(let scenario):
                            items.append(WorkItem(
                                scenario: scenario,
                                featureBackground: featureBackground,
                                ruleBackground: ruleBackground,
                                ruleTags: rule.tags
                            ))
                        }
                    }
                }
            }
        }
        self.workItems = items
    }

    public mutating func next() -> Pickle? {
        while workIndex < workItems.count {
            let item = workItems[workIndex]
            let scenario = item.scenario

            if scenario.examples.isEmpty {
                workIndex += 1
                // Scenario Outline with no examples → 0 pickles; simple Scenario → 1 pickle
                if outlineKeywords.contains(scenario.keyword) {
                    continue
                }
                return makePickle(for: item, exampleValues: nil, examplesRowIndex: nil, examplesTags: [])
            } else {
                // Scenario Outline → need to iterate through examples rows
                // Find the current examples/row position
                if let result = nextOutlinePickle(for: item) {
                    return result
                }
                // All rows exhausted, move to next work item
                workIndex += 1
            }
        }
        return nil
    }

    /// State for iterating through outline examples.
    private var outlineExamplesIndex: Int = 0
    private var outlineRowIndex: Int = 0

    private mutating func nextOutlinePickle(for item: WorkItem) -> Pickle? {
        let scenario = item.scenario
        let examples = scenario.examples

        while outlineExamplesIndex < examples.count {
            let exBlock = examples[outlineExamplesIndex]
            guard let header = exBlock.tableHeader else {
                outlineExamplesIndex += 1
                outlineRowIndex = 0
                continue
            }

            if outlineRowIndex < exBlock.tableBody.count {
                let row = exBlock.tableBody[outlineRowIndex]
                outlineRowIndex += 1

                let headers = header.cells.map(\.value)
                let cellValues = row.cells.map(\.value)

                var values: [String: String] = [:]
                values.reserveCapacity(headers.count)
                for (h, v) in zip(headers, cellValues) {
                    values[h] = v
                }

                return makePickle(
                    for: item,
                    exampleValues: values,
                    examplesRowIndex: outlineRowIndex - 1,
                    examplesTags: exBlock.tags
                )
            } else {
                outlineExamplesIndex += 1
                outlineRowIndex = 0
            }
        }

        // Reset for next work item
        outlineExamplesIndex = 0
        outlineRowIndex = 0
        return nil
    }

    private mutating func makePickle(
        for item: WorkItem,
        exampleValues: [String: String]?,
        examplesRowIndex: Int?,
        examplesTags: [Tag]
    ) -> Pickle {
        let scenario = item.scenario
        let id = nextId()

        // Build name
        var name = scenario.name
        if let values = exampleValues {
            name = ExampleExpansion.substitute(in: name, values: values)
        }

        // Build tags: feature ∪ rule ∪ scenario ∪ examples
        var tags: [PickleTag] = []
        tags.reserveCapacity(
            featureTags.count + item.ruleTags.count + scenario.tags.count + examplesTags.count
        )
        for tag in featureTags {
            tags.append(PickleTag(name: tag.name, astNodeId: tagId(tag)))
        }
        for tag in item.ruleTags {
            tags.append(PickleTag(name: tag.name, astNodeId: tagId(tag)))
        }
        for tag in scenario.tags {
            tags.append(PickleTag(name: tag.name, astNodeId: tagId(tag)))
        }
        for tag in examplesTags {
            tags.append(PickleTag(name: tag.name, astNodeId: tagId(tag)))
        }

        // Build steps: feature bg + rule bg + scenario steps
        var steps: [PickleStep] = []

        if let featureBg = item.featureBackground {
            for step in featureBg.steps {
                steps.append(makePickleStep(step, exampleValues: exampleValues))
            }
        }
        if let ruleBg = item.ruleBackground {
            for step in ruleBg.steps {
                steps.append(makePickleStep(step, exampleValues: exampleValues))
            }
        }
        for step in scenario.steps {
            steps.append(makePickleStep(step, exampleValues: exampleValues))
        }

        // Build ast node IDs
        var astNodeIds = ["\(scenario.location.line):\(scenario.location.column)"]
        if let rowIdx = examplesRowIndex {
            astNodeIds.append("row:\(rowIdx)")
        }

        return Pickle(
            id: id,
            uri: uri,
            name: name,
            language: language,
            tags: tags,
            steps: steps,
            astNodeIds: astNodeIds
        )
    }

    private mutating func makePickleStep(
        _ step: Step,
        exampleValues: [String: String]?
    ) -> PickleStep {
        let id = nextId()

        var text = step.text
        if let values = exampleValues {
            text = ExampleExpansion.substitute(in: text, values: values)
        }

        var argument: PickleStepArgument?
        if let ds = step.docString {
            if let values = exampleValues {
                argument = .docString(ExampleExpansion.substitute(in: ds, values: values))
            } else {
                argument = .docString(ds)
            }
        } else if let dt = step.dataTable {
            if let values = exampleValues {
                argument = .dataTable(ExampleExpansion.substitute(in: dt, values: values))
            } else {
                argument = .dataTable(dt)
            }
        }

        let astNodeId = "\(step.location.line):\(step.location.column)"

        return PickleStep(
            id: id,
            text: text,
            argument: argument,
            astNodeIds: [astNodeId]
        )
    }

    private mutating func nextId() -> String {
        idCounter += 1
        return "\(idCounter)"
    }

    private func tagId(_ tag: Tag) -> String {
        "\(tag.location.line):\(tag.location.column)"
    }
}

/// A work item representing a scenario to compile, with its inherited context.
private struct WorkItem: Sendable {
    let scenario: Scenario
    let featureBackground: Background?
    let ruleBackground: Background?
    let ruleTags: [Tag]
}
