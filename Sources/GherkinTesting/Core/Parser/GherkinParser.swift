// GherkinParser.swift
// GherkinTesting
//
// Copyright © 2026 Atelier Socle. MIT License.

/// A parser that transforms Gherkin source text into a ``GherkinDocument`` AST.
///
/// The parser tokenizes the source using ``GherkinLexer``, then consumes
/// the token stream to build the full AST. It handles the complete Gherkin v6+
/// specification including Feature, Rule, Background, Scenario, Scenario Outline,
/// Examples, Steps (with And/But resolution), DataTable, DocString, Tags,
/// Comments, and multiline Descriptions.
///
/// ```swift
/// let parser = GherkinParser()
/// let document = try parser.parse(source: featureSource)
///
/// if let feature = document.feature {
///     for scenario in feature.scenarios {
///         print("Scenario: \(scenario.name)")
///     }
/// }
/// ```
public struct GherkinParser: Sendable {

    /// Creates a new Gherkin parser.
    public init() {}

    /// Parses Gherkin source text into a ``GherkinDocument``.
    ///
    /// - Parameter source: The complete Gherkin source text.
    /// - Returns: A ``GherkinDocument`` representing the parsed AST.
    /// - Throws: ``ParserError`` if the source contains syntax errors.
    public func parse(source: String) throws -> GherkinDocument {
        let lexer = GherkinLexer(source: source)
        let tokens = lexer.tokenize()
        var context = ParserContext(tokens: tokens, source: source)
        return try context.parseDocument()
    }
}

/// Internal mutable parsing context that tracks position in the token stream.
private struct ParserContext {
    let tokens: [Token]
    let source: String
    var position: Int = 0
    var comments: [Comment] = []

    /// The detected language from the source.
    var language: String {
        LanguageDetector.detectLanguageCode(from: source) ?? "en"
    }

    // MARK: - Token Navigation

    var currentToken: Token {
        guard position < tokens.count else {
            return Token(type: .eof, location: Location(line: 1))
        }
        return tokens[position]
    }

    var isAtEnd: Bool {
        currentToken.type == .eof
    }

    @discardableResult
    mutating func advance() -> Token {
        let token = currentToken
        if position < tokens.count {
            position += 1
        }
        return token
    }

    mutating func skipWhitespaceAndComments() {
        while !isAtEnd {
            switch currentToken.type {
            case .empty:
                advance()
            case .comment:
                let token = advance()
                comments.append(Comment(
                    location: token.location,
                    text: token.text
                ))
            case .language:
                // Language directive is NOT a comment per the spec — skip it silently
                advance()
            default:
                return
            }
        }
    }

    // MARK: - Document Parsing

    mutating func parseDocument() throws -> GherkinDocument {
        skipWhitespaceAndComments()

        var feature: Feature?
        if !isAtEnd {
            if currentToken.type == .tagLine || currentToken.type == .feature {
                feature = try parseFeature()
            } else {
                // Skip any remaining content after consuming comments/empty lines
                // that isn't a feature. Consume trailing comments and empty lines.
                skipRemainingContent()
            }
        }

        return GherkinDocument(feature: feature, comments: comments)
    }

    mutating func skipRemainingContent() {
        while !isAtEnd {
            let token = currentToken
            switch token.type {
            case .comment:
                let t = advance()
                comments.append(Comment(location: t.location, text: t.text))
            case .empty:
                advance()
            default:
                advance()
            }
        }
    }

    // MARK: - Feature Parsing

    mutating func parseFeature() throws -> Feature {
        let tags = parseTags()
        skipWhitespaceAndComments()

        guard currentToken.type == .feature else {
            throw ParserError.unexpectedToken(currentToken, expected: "Feature keyword")
        }

        let featureToken = advance()
        let description = parseDescription()

        var children: [FeatureChild] = []

        while !isAtEnd {
            skipWhitespaceAndComments()
            if isAtEnd { break }

            let nextTags = parseTags()
            skipWhitespaceAndComments()
            if isAtEnd { break }

            switch currentToken.type {
            case .background:
                if children.contains(where: {
                    if case .background = $0 { return true }
                    return false
                }) {
                    throw ParserError.duplicateBackground(at: currentToken.location)
                }
                let bg = try parseBackground()
                children.append(.background(bg))
            case .scenario, .scenarioOutline:
                let scenario = try parseScenario(tags: nextTags)
                children.append(.scenario(scenario))
            case .rule:
                let rule = try parseRule(tags: nextTags)
                children.append(.rule(rule))
            case .eof:
                break
            default:
                // Consume unexpected tokens and continue
                advance()
            }
        }

        return Feature(
            location: featureToken.location,
            tags: tags,
            language: language,
            keyword: featureToken.keyword ?? "Feature",
            name: featureToken.text,
            description: description,
            children: children
        )
    }

    // MARK: - Rule Parsing

    mutating func parseRule(tags: [Tag]) throws -> Rule {
        guard currentToken.type == .rule else {
            throw ParserError.unexpectedToken(currentToken, expected: "Rule keyword")
        }

        let ruleToken = advance()
        let description = parseDescription()

        var children: [RuleChild] = []

        while !isAtEnd {
            skipWhitespaceAndComments()
            if isAtEnd { break }

            // Check if we hit something that belongs to the parent (another Rule, Feature-level tag+scenario)
            if currentToken.type == .rule { break }
            if currentToken.type == .feature { break }

            // Peek ahead for tags that might precede a rule (which ends this rule)
            if currentToken.type == .tagLine {
                if isTagFollowedByRule() { break }
            }

            let nextTags = parseTags()
            skipWhitespaceAndComments()
            if isAtEnd { break }

            switch currentToken.type {
            case .background:
                if children.contains(where: {
                    if case .background = $0 { return true }
                    return false
                }) {
                    throw ParserError.duplicateBackground(at: currentToken.location)
                }
                let bg = try parseBackground()
                children.append(.background(bg))
            case .scenario, .scenarioOutline:
                let scenario = try parseScenario(tags: nextTags)
                children.append(.scenario(scenario))
            case .rule, .feature:
                break
            default:
                advance()
            }
        }

        return Rule(
            location: ruleToken.location,
            tags: tags,
            keyword: ruleToken.keyword ?? "Rule",
            name: ruleToken.text,
            description: description,
            children: children
        )
    }

    /// Checks if the current tag line is followed by a Rule keyword (possibly with more tags in between).
    func isTagFollowedByRule() -> Bool {
        var lookahead = position
        while lookahead < tokens.count {
            let type = tokens[lookahead].type
            switch type {
            case .tagLine, .empty, .comment:
                lookahead += 1
            case .rule:
                return true
            default:
                return false
            }
        }
        return false
    }

    // MARK: - Background Parsing

    mutating func parseBackground() throws -> Background {
        guard currentToken.type == .background else {
            throw ParserError.unexpectedToken(currentToken, expected: "Background keyword")
        }

        let bgToken = advance()
        let description = parseDescription()
        let steps = try parseSteps()

        return Background(
            location: bgToken.location,
            keyword: bgToken.keyword ?? "Background",
            name: bgToken.text,
            description: description,
            steps: steps
        )
    }

    // MARK: - Scenario Parsing

    mutating func parseScenario(tags: [Tag]) throws -> Scenario {
        let isOutline = currentToken.type == .scenarioOutline
        guard currentToken.type == .scenario || isOutline else {
            throw ParserError.unexpectedToken(currentToken, expected: "Scenario keyword")
        }

        let scenarioToken = advance()
        let description = parseDescription()
        let steps = try parseSteps()
        var examples: [Examples] = []

        if isOutline {
            while !isAtEnd {
                skipWhitespaceAndComments()
                if isAtEnd { break }

                // Collect tags that might belong to examples
                if currentToken.type == .tagLine {
                    if isTagFollowedByExamples() {
                        let exTags = parseTags()
                        skipWhitespaceAndComments()
                        if currentToken.type == .examples {
                            let ex = try parseExamples(tags: exTags)
                            examples.append(ex)
                            continue
                        }
                    }
                    break
                }

                if currentToken.type == .examples {
                    let ex = try parseExamples(tags: [])
                    examples.append(ex)
                } else {
                    break
                }
            }
        }

        return Scenario(
            location: scenarioToken.location,
            tags: tags,
            keyword: scenarioToken.keyword ?? (isOutline ? "Scenario Outline" : "Scenario"),
            name: scenarioToken.text,
            description: description,
            steps: steps,
            examples: examples
        )
    }

    /// Checks if the current tag line is followed by an Examples keyword.
    func isTagFollowedByExamples() -> Bool {
        var lookahead = position
        while lookahead < tokens.count {
            let type = tokens[lookahead].type
            switch type {
            case .tagLine, .empty, .comment:
                lookahead += 1
            case .examples:
                return true
            default:
                return false
            }
        }
        return false
    }

    // MARK: - Examples Parsing

    mutating func parseExamples(tags: [Tag]) throws -> Examples {
        guard currentToken.type == .examples else {
            throw ParserError.unexpectedToken(currentToken, expected: "Examples keyword")
        }

        let exToken = advance()
        let description = parseDescription()

        // Determine name: empty string → nil per spec
        let rawName = exToken.text
        let name: String? = rawName.isEmpty ? nil : rawName

        // Parse table header
        skipWhitespaceAndComments()
        var tableHeader: TableRow?
        var tableBody: [TableRow] = []

        if currentToken.type == .tableRow {
            tableHeader = parseTableRow()

            // Parse table body rows
            while !isAtEnd {
                skipWhitespaceAndComments()
                if currentToken.type == .tableRow {
                    tableBody.append(parseTableRow())
                } else {
                    break
                }
            }
        }

        return Examples(
            location: exToken.location,
            tags: tags,
            keyword: exToken.keyword ?? "Examples",
            name: name,
            description: description,
            tableHeader: tableHeader,
            tableBody: tableBody
        )
    }

    // MARK: - Step Parsing

    mutating func parseSteps() throws -> [Step] {
        var steps: [Step] = []
        var lastKeywordType: StepKeywordType = .unknown

        while !isAtEnd {
            skipWhitespaceAndComments()
            if isAtEnd { break }

            guard currentToken.type == .step else { break }

            let stepToken = advance()
            let keyword = stepToken.keyword ?? ""

            // Determine keyword type
            let lang = LanguageRegistry.language(for: language) ?? LanguageRegistry.defaultLanguage
            let rawType = resolveStepKeywordType(keyword: keyword, language: lang)
            let keywordType: StepKeywordType
            if rawType == .conjunction {
                keywordType = lastKeywordType == .unknown ? .unknown : lastKeywordType
            } else if rawType == .unknown {
                // Wildcard * stays .unknown per spec — does NOT inherit
                keywordType = .unknown
            } else {
                keywordType = rawType
            }

            if keywordType != .unknown {
                lastKeywordType = keywordType
            }

            // Check for doc string or data table
            var docString: DocString?
            var dataTable: DataTable?

            skipWhitespaceAndComments()

            if !isAtEnd && currentToken.type == .docString {
                docString = try parseDocString()
            } else if !isAtEnd && currentToken.type == .tableRow {
                dataTable = parseDataTable()
            }

            steps.append(Step(
                location: stepToken.location,
                keyword: keyword,
                keywordType: keywordType,
                text: stepToken.text,
                docString: docString,
                dataTable: dataTable
            ))
        }

        return steps
    }

    /// Determines the raw keyword type for a step keyword string.
    func resolveStepKeywordType(keyword: String, language: GherkinLanguage) -> StepKeywordType {
        // Wildcard `* ` → .unknown per the Gherkin specification
        if keyword == "* " {
            return .unknown
        }

        if language.given.contains(keyword) && !language.and.contains(keyword) && !language.but.contains(keyword) {
            return .context
        }
        if language.when.contains(keyword) && !language.and.contains(keyword) && !language.but.contains(keyword) {
            return .action
        }
        if language.then.contains(keyword) && !language.and.contains(keyword) && !language.but.contains(keyword) {
            return .outcome
        }

        // Check if it's exclusively an and/but keyword
        if language.and.contains(keyword) || language.but.contains(keyword) {
            // Could also be in given/when/then due to "* " — check if it's uniquely and/but
            let isGiven = language.given.contains(keyword)
            let isWhen = language.when.contains(keyword)
            let isThen = language.then.contains(keyword)
            if !isGiven && !isWhen && !isThen {
                return .conjunction
            }
            // If it appears in both given/when/then AND and/but, treat as the primary type
            if isGiven { return .context }
            if isWhen { return .action }
            if isThen { return .outcome }
        }

        return .conjunction
    }

    // MARK: - DocString Parsing

    mutating func parseDocString() throws -> DocString {
        guard currentToken.type == .docString else {
            throw ParserError.unexpectedToken(currentToken, expected: "doc string delimiter")
        }

        let openToken = advance()
        let delimiter = openToken.keyword ?? "\"\"\""
        let mediaType = openToken.text.isEmpty ? nil : openToken.text

        var lines: [String] = []

        while !isAtEnd {
            if currentToken.type == .docString {
                // Closing delimiter
                advance()
                break
            } else if currentToken.type == .docStringContent {
                lines.append(currentToken.text)
                advance()
            } else if currentToken.type == .eof {
                throw ParserError.unexpectedEOF(
                    at: currentToken.location,
                    expected: "closing doc string delimiter '\(delimiter)'"
                )
            } else {
                // Shouldn't happen if lexer is correct, but be safe
                lines.append(currentToken.text)
                advance()
            }
        }

        let content = lines.joined(separator: "\n")

        return DocString(
            location: openToken.location,
            mediaType: mediaType,
            content: content,
            delimiter: delimiter
        )
    }

    // MARK: - DataTable Parsing

    mutating func parseDataTable() -> DataTable {
        var rows: [TableRow] = []
        let startLocation = currentToken.location

        while !isAtEnd && currentToken.type == .tableRow {
            rows.append(parseTableRow())
            // Skip empty lines between table rows (but not comments — those break the table)
            while !isAtEnd && currentToken.type == .empty {
                advance()
            }
        }

        return DataTable(location: startLocation, rows: rows)
    }

    mutating func parseTableRow() -> TableRow {
        let token = advance()
        let cells = (token.items ?? []).map { cellToken in
            TableCell(
                location: Location(line: token.location.line, column: cellToken.column),
                value: cellToken.value
            )
        }
        return TableRow(location: token.location, cells: cells)
    }

    // MARK: - Tags Parsing

    mutating func parseTags() -> [Tag] {
        var tags: [Tag] = []

        while !isAtEnd && currentToken.type == .tagLine {
            let token = advance()
            let tagStrings = token.text.split(separator: " ").map(String.init)
            var col = token.location.column

            for tagStr in tagStrings {
                let trimmed = tagStr.trimmingCharacters(in: .whitespaces)
                if trimmed.hasPrefix("@") && trimmed.count > 1 {
                    tags.append(Tag(
                        location: Location(line: token.location.line, column: col),
                        name: trimmed
                    ))
                }
                col += tagStr.count + 1
            }

            // Skip empty lines between tag lines
            while !isAtEnd && currentToken.type == .empty {
                advance()
            }
            // Also consume comments between tag lines
            while !isAtEnd && currentToken.type == .comment {
                let commentToken = advance()
                comments.append(Comment(location: commentToken.location, text: commentToken.text))
            }
        }

        return tags
    }

    // MARK: - Description Parsing

    mutating func parseDescription() -> String? {
        var lines: [String] = []

        // Skip initial empty lines after keyword
        while !isAtEnd && currentToken.type == .empty {
            advance()
        }

        while !isAtEnd {
            switch currentToken.type {
            case .other:
                lines.append(currentToken.text)
                advance()
            case .empty:
                // Blank lines within a description are preserved
                lines.append("")
                advance()
            case .comment:
                // Comments within description area are captured as comments
                let commentToken = advance()
                comments.append(Comment(location: commentToken.location, text: commentToken.text))
            default:
                break
            }

            // Check if we should stop
            if currentToken.type != .other && currentToken.type != .empty && currentToken.type != .comment {
                break
            }
        }

        // Trim trailing empty lines
        while let last = lines.last, last.isEmpty {
            lines.removeLast()
        }

        guard !lines.isEmpty else { return nil }
        return lines.joined(separator: "\n")
    }
}
