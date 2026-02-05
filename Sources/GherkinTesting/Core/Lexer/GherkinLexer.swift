// GherkinLexer.swift
// GherkinTesting
//
// Copyright © 2026 Atelier Socle. MIT License.

/// A line-by-line tokenizer for Gherkin `.feature` files.
///
/// The lexer processes source text one line at a time, classifying each line
/// as a keyword, tag, comment, table row, doc string delimiter, or plain text.
/// It is language-aware and uses the provided ``GherkinLanguage`` for keyword matching.
///
/// ```swift
/// let lexer = GherkinLexer(source: featureText)
/// let tokens = lexer.tokenize()
/// ```
public struct GherkinLexer: Sendable {

    /// The source text to tokenize.
    private let source: String

    /// The language used for keyword matching.
    private let language: GherkinLanguage

    /// Creates a new lexer for the given source text.
    ///
    /// The language is auto-detected from the `# language:` header if present,
    /// otherwise defaults to English.
    ///
    /// - Parameter source: The Gherkin source text to tokenize.
    public init(source: String) {
        self.source = source
        self.language = LanguageDetector.detectLanguage(from: source)
    }

    /// Creates a new lexer for the given source text with an explicit language.
    ///
    /// - Parameters:
    ///   - source: The Gherkin source text to tokenize.
    ///   - language: The ``GherkinLanguage`` to use for keyword matching.
    public init(source: String, language: GherkinLanguage) {
        self.source = source
        self.language = language
    }

    /// Tokenizes the entire source text into an array of tokens.
    ///
    /// - Returns: An array of ``Token`` values, one per logical line, ending with an `.eof` token.
    public func tokenize() -> [Token] {
        let lines = source.split(separator: "\n", omittingEmptySubsequences: false)
        var tokens: [Token] = []
        tokens.reserveCapacity(lines.count + 1)

        var inDocString = false
        var docStringDelimiter = ""
        var docStringIndent = 0

        for (index, line) in lines.enumerated() {
            let lineNumber = index + 1
            let lineStr = String(line)

            if inDocString {
                let trimmed = lineStr.trimmingCharacters(in: .whitespaces)
                if trimmed.hasPrefix(docStringDelimiter) {
                    // End of doc string
                    let col = lineStr.distance(
                        from: lineStr.startIndex,
                        to: lineStr.firstIndex(where: { !$0.isWhitespace }) ?? lineStr.startIndex
                    ) + 1
                    tokens.append(Token(
                        type: .docString,
                        location: Location(line: lineNumber, column: col),
                        keyword: docStringDelimiter,
                        text: ""
                    ))
                    inDocString = false
                    docStringDelimiter = ""
                } else {
                    // Content inside doc string — remove indentation up to the opening delimiter's indent
                    let content: String
                    if docStringIndent > 0 && lineStr.count >= docStringIndent {
                        let prefixToRemove = lineStr.prefix(docStringIndent)
                        if prefixToRemove.allSatisfy({ $0.isWhitespace }) {
                            content = String(lineStr.dropFirst(docStringIndent))
                        } else {
                            content = lineStr
                        }
                    } else {
                        content = lineStr
                    }
                    tokens.append(Token(
                        type: .docStringContent,
                        location: Location(line: lineNumber, column: 1),
                        text: content
                    ))
                }
                continue
            }

            let trimmed = lineStr.trimmingCharacters(in: .whitespaces)

            // Empty line
            if trimmed.isEmpty {
                tokens.append(Token(
                    type: .empty,
                    location: Location(line: lineNumber, column: 1)
                ))
                continue
            }

            // Comment line
            if trimmed.hasPrefix("#") {
                // Check for language directive
                let afterHash = trimmed.dropFirst().trimmingCharacters(in: .whitespaces)
                if afterHash.lowercased().hasPrefix("language:") {
                    let codeStart = afterHash.index(afterHash.startIndex, offsetBy: 9)
                    let code = afterHash[codeStart...].trimmingCharacters(in: .whitespaces)
                    let col = columnOf(firstNonWhitespace: lineStr)
                    tokens.append(Token(
                        type: .language,
                        location: Location(line: lineNumber, column: col),
                        keyword: "# language:",
                        text: code
                    ))
                } else {
                    let col = columnOf(firstNonWhitespace: lineStr)
                    tokens.append(Token(
                        type: .comment,
                        location: Location(line: lineNumber, column: col),
                        text: trimmed
                    ))
                }
                continue
            }

            // Tag line
            if trimmed.hasPrefix("@") {
                let col = columnOf(firstNonWhitespace: lineStr)
                tokens.append(Token(
                    type: .tagLine,
                    location: Location(line: lineNumber, column: col),
                    text: trimmed
                ))
                continue
            }

            // Doc string opening
            if trimmed.hasPrefix("\"\"\"") || trimmed.hasPrefix("```") {
                let delimiter = trimmed.hasPrefix("\"\"\"") ? "\"\"\"" : "```"
                let mediaType = String(trimmed.dropFirst(3)).trimmingCharacters(in: .whitespaces)
                let col = columnOf(firstNonWhitespace: lineStr)
                docStringIndent = col - 1
                tokens.append(Token(
                    type: .docString,
                    location: Location(line: lineNumber, column: col),
                    keyword: delimiter,
                    text: mediaType
                ))
                inDocString = true
                docStringDelimiter = delimiter
                continue
            }

            // Table row
            if trimmed.hasPrefix("|") {
                let col = columnOf(firstNonWhitespace: lineStr)
                let cells = parseTableCells(line: lineStr, lineNumber: lineNumber)
                tokens.append(Token(
                    type: .tableRow,
                    location: Location(line: lineNumber, column: col),
                    text: trimmed,
                    items: cells
                ))
                continue
            }

            // Keyword matching
            if let token = matchKeyword(line: lineStr, trimmed: trimmed, lineNumber: lineNumber) {
                tokens.append(token)
                continue
            }

            // Other (description or unrecognized text)
            let col = columnOf(firstNonWhitespace: lineStr)
            tokens.append(Token(
                type: .other,
                location: Location(line: lineNumber, column: col),
                text: trimmed
            ))
        }

        // EOF
        tokens.append(Token(
            type: .eof,
            location: Location(line: source.split(separator: "\n", omittingEmptySubsequences: false).count + 1),
            text: ""
        ))

        return tokens
    }

    // MARK: - Private Helpers

    /// Returns the 1-based column of the first non-whitespace character.
    private func columnOf(firstNonWhitespace line: String) -> Int {
        for (index, char) in line.enumerated() {
            if !char.isWhitespace {
                return index + 1
            }
        }
        return 1
    }

    /// Attempts to match a keyword at the start of the trimmed line.
    private func matchKeyword(line: String, trimmed: String, lineNumber: Int) -> Token? {
        // Try feature keywords
        for kw in language.feature {
            if let token = matchStructuralKeyword(trimmed: trimmed, line: line, keyword: kw,
                                                   type: .feature, lineNumber: lineNumber) {
                return token
            }
        }

        // Try rule keywords
        for kw in language.rule {
            if let token = matchStructuralKeyword(trimmed: trimmed, line: line, keyword: kw,
                                                   type: .rule, lineNumber: lineNumber) {
                return token
            }
        }

        // Try background keywords
        for kw in language.background {
            if let token = matchStructuralKeyword(trimmed: trimmed, line: line, keyword: kw,
                                                   type: .background, lineNumber: lineNumber) {
                return token
            }
        }

        // Try scenario outline keywords (must be before scenario to match longer keywords first)
        for kw in language.scenarioOutline {
            if let token = matchStructuralKeyword(trimmed: trimmed, line: line, keyword: kw,
                                                   type: .scenarioOutline, lineNumber: lineNumber) {
                return token
            }
        }

        // Try scenario keywords
        for kw in language.scenario {
            if let token = matchStructuralKeyword(trimmed: trimmed, line: line, keyword: kw,
                                                   type: .scenario, lineNumber: lineNumber) {
                return token
            }
        }

        // Try examples keywords
        for kw in language.examples {
            if let token = matchStructuralKeyword(trimmed: trimmed, line: line, keyword: kw,
                                                   type: .examples, lineNumber: lineNumber) {
                return token
            }
        }

        // Try step keywords (these include trailing space)
        if let token = matchStepKeyword(trimmed: trimmed, line: line, lineNumber: lineNumber) {
            return token
        }

        return nil
    }

    /// Matches a structural keyword (Feature, Scenario, etc.) followed by `:`.
    private func matchStructuralKeyword(
        trimmed: String,
        line: String,
        keyword: String,
        type: TokenType,
        lineNumber: Int
    ) -> Token? {
        let kwWithColon = keyword + ":"
        guard trimmed.hasPrefix(kwWithColon) else { return nil }

        let col = columnOf(firstNonWhitespace: line)
        let rest = String(trimmed.dropFirst(kwWithColon.count)).trimmingCharacters(in: .whitespaces)
        return Token(
            type: type,
            location: Location(line: lineNumber, column: col),
            keyword: keyword,
            text: rest
        )
    }

    /// Matches a step keyword (Given, When, Then, And, But, *) at the start of the line.
    private func matchStepKeyword(trimmed: String, line: String, lineNumber: Int) -> Token? {
        // Step keywords in gherkin-languages.json include trailing space (e.g. "Given ")
        // except for "* " which also includes trailing space
        let allKeywords: [(keyword: String, type: StepKeywordType)] =
            language.given.map { ($0, .context) } +
            language.when.map { ($0, .action) } +
            language.then.map { ($0, .outcome) } +
            language.and.map { ($0, .conjunction) } +
            language.but.map { ($0, .conjunction) }

        // Sort by length descending to match longest keyword first
        let sorted = allKeywords.sorted { $0.keyword.count > $1.keyword.count }

        for (keyword, _) in sorted {
            if trimmed.hasPrefix(keyword) {
                let col = columnOf(firstNonWhitespace: line)
                let rest = String(trimmed.dropFirst(keyword.count))
                return Token(
                    type: .step,
                    location: Location(line: lineNumber, column: col),
                    keyword: keyword,
                    text: rest
                )
            }
        }

        return nil
    }

    /// Parses table cells from a pipe-delimited line.
    ///
    /// Handles escaping: `\|` → `|`, `\n` → newline, `\\` → `\`.
    private func parseTableCells(line: String, lineNumber: Int) -> [TableCellToken] {
        var cells: [TableCellToken] = []
        var currentValue = ""
        var inCell = false
        var cellStartColumn = 0
        var escaped = false
        var column = 0

        for char in line {
            column += 1

            if escaped {
                switch char {
                case "|":
                    currentValue.append("|")
                case "n":
                    currentValue.append("\n")
                case "\\":
                    currentValue.append("\\")
                default:
                    currentValue.append("\\")
                    currentValue.append(char)
                }
                escaped = false
                continue
            }

            if char == "\\" {
                escaped = true
                continue
            }

            if char == "|" {
                if inCell {
                    // End of a cell
                    let trimmedValue = currentValue.trimmingCharacters(in: .whitespaces)
                    cells.append(TableCellToken(column: cellStartColumn, value: trimmedValue))
                    currentValue = ""
                }
                // Start of next cell
                inCell = true
                cellStartColumn = column + 1
                currentValue = ""
                continue
            }

            if inCell {
                currentValue.append(char)
            }
        }

        return cells
    }
}
