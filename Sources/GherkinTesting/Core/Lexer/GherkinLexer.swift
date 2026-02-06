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

    /// Pre-sorted step keywords (longest first), computed once at init.
    private let sortedStepKeywords: [(keyword: String, type: StepKeywordType)]

    /// Creates a new lexer for the given source text.
    ///
    /// The language is auto-detected from the `# language:` header if present,
    /// otherwise defaults to English.
    ///
    /// - Parameter source: The Gherkin source text to tokenize.
    public init(source: String) {
        self.source = source
        let lang = LanguageDetector.detectLanguage(from: source)
        self.language = lang
        self.sortedStepKeywords = Self.buildSortedStepKeywords(language: lang)
    }

    /// Creates a new lexer for the given source text with an explicit language.
    ///
    /// - Parameters:
    ///   - source: The Gherkin source text to tokenize.
    ///   - language: The ``GherkinLanguage`` to use for keyword matching.
    public init(source: String, language: GherkinLanguage) {
        self.source = source
        self.language = language
        self.sortedStepKeywords = Self.buildSortedStepKeywords(language: language)
    }

    /// Builds the sorted step keywords array for the given language.
    private static func buildSortedStepKeywords(
        language: GherkinLanguage
    ) -> [(keyword: String, type: StepKeywordType)] {
        let allKeywords: [(keyword: String, type: StepKeywordType)] =
            language.given.map { ($0, .context) } + language.when.map { ($0, .action) } + language.then.map { ($0, .outcome) }
            + language.and.map { ($0, .conjunction) } + language.but.map { ($0, .conjunction) }
        return allKeywords.sorted { $0.keyword.count > $1.keyword.count }
    }

    /// Tokenizes the entire source text into an array of tokens.
    ///
    /// - Returns: An array of ``Token`` values, one per logical line, ending with an `.eof` token.
    public func tokenize() -> [Token] {
        let lines = source.split(separator: "\n", omittingEmptySubsequences: false)
        var tokens: [Token] = []
        tokens.reserveCapacity(lines.count + 1)
        var docState = DocStringState()

        for (index, line) in lines.enumerated() {
            let lineNumber = index + 1
            let lineStr = String(line)

            if docState.active {
                processDocStringLine(lineStr: lineStr, lineNumber: lineNumber, state: &docState, tokens: &tokens)
                continue
            }

            let trimmed = lineStr.trimmingCharacters(in: .whitespaces)

            if trimmed.isEmpty {
                tokens.append(Token(type: .empty, location: Location(line: lineNumber, column: 1)))
                continue
            }

            if trimmed.hasPrefix("#") {
                tokens.append(tokenizeComment(lineStr: lineStr, trimmed: trimmed, lineNumber: lineNumber))
                continue
            }

            if trimmed.hasPrefix("@") {
                let col = columnOf(firstNonWhitespace: lineStr)
                tokens.append(Token(type: .tagLine, location: Location(line: lineNumber, column: col), text: trimmed))
                continue
            }

            if let opening = tokenizeDocStringOpening(lineStr: lineStr, trimmed: trimmed, lineNumber: lineNumber, state: &docState) {
                tokens.append(opening)
                continue
            }

            if trimmed.hasPrefix("|") {
                let col = columnOf(firstNonWhitespace: lineStr)
                let cells = parseTableCells(line: lineStr, lineNumber: lineNumber)
                tokens.append(Token(type: .tableRow, location: Location(line: lineNumber, column: col), text: trimmed, items: cells))
                continue
            }

            if let token = matchKeyword(line: lineStr, trimmed: trimmed, lineNumber: lineNumber) {
                tokens.append(token)
                continue
            }

            let col = columnOf(firstNonWhitespace: lineStr)
            tokens.append(Token(type: .other, location: Location(line: lineNumber, column: col), text: trimmed))
        }

        tokens.append(Token(type: .eof, location: Location(line: lines.count + 1), text: ""))
        return tokens
    }

    // MARK: - Doc String Helpers

    /// Mutable state tracked during multi-line doc string tokenization.
    private struct DocStringState {
        var active = false
        var delimiter = ""
        var indent = 0
    }

    /// Processes a line inside a doc string block.
    ///
    /// - Parameters:
    ///   - lineStr: The raw line string.
    ///   - lineNumber: The 1-based line number.
    ///   - state: The doc string state to update.
    ///   - tokens: The token array to append to.
    private func processDocStringLine(
        lineStr: String,
        lineNumber: Int,
        state: inout DocStringState,
        tokens: inout [Token]
    ) {
        let trimmed = lineStr.trimmingCharacters(in: .whitespaces)
        if trimmed.hasPrefix(state.delimiter) {
            let col = columnOf(firstNonWhitespace: lineStr)
            tokens.append(
                Token(
                    type: .docString,
                    location: Location(line: lineNumber, column: col),
                    keyword: state.delimiter,
                    text: ""
                ))
            state.active = false
            state.delimiter = ""
        } else {
            let content = extractDocStringContent(lineStr: lineStr, indent: state.indent)
            tokens.append(
                Token(
                    type: .docStringContent,
                    location: Location(line: lineNumber, column: 1),
                    text: content
                ))
        }
    }

    /// Removes leading indentation from a doc string content line.
    ///
    /// - Parameters:
    ///   - lineStr: The raw line string.
    ///   - indent: The indent level of the opening delimiter.
    /// - Returns: The content with leading indentation stripped.
    private func extractDocStringContent(lineStr: String, indent: Int) -> String {
        if indent > 0 && lineStr.count >= indent {
            let prefixToRemove = lineStr.prefix(indent)
            if prefixToRemove.allSatisfy({ $0.isWhitespace }) {
                return String(lineStr.dropFirst(indent))
            }
        }
        return lineStr
    }

    // MARK: - Line Classification Helpers

    /// Tokenizes a comment or language directive line.
    ///
    /// - Parameters:
    ///   - lineStr: The raw line string.
    ///   - trimmed: The whitespace-trimmed line.
    ///   - lineNumber: The 1-based line number.
    /// - Returns: A `.comment` or `.language` token.
    private func tokenizeComment(lineStr: String, trimmed: String, lineNumber: Int) -> Token {
        let afterHash = trimmed.dropFirst().trimmingCharacters(in: .whitespaces)
        if afterHash.lowercased().hasPrefix("language:") {
            let codeStart = afterHash.index(afterHash.startIndex, offsetBy: 9)
            let code = afterHash[codeStart...].trimmingCharacters(in: .whitespaces)
            let col = columnOf(firstNonWhitespace: lineStr)
            return Token(
                type: .language,
                location: Location(line: lineNumber, column: col),
                keyword: "# language:",
                text: code
            )
        }
        let col = columnOf(firstNonWhitespace: lineStr)
        return Token(
            type: .comment,
            location: Location(line: lineNumber, column: col),
            text: trimmed
        )
    }

    /// Detects and tokenizes a doc string opening delimiter.
    ///
    /// - Parameters:
    ///   - lineStr: The raw line string.
    ///   - trimmed: The whitespace-trimmed line.
    ///   - lineNumber: The 1-based line number.
    ///   - state: The doc string state to update if opening is found.
    /// - Returns: A `.docString` token if the line opens a doc string, `nil` otherwise.
    private func tokenizeDocStringOpening(
        lineStr: String,
        trimmed: String,
        lineNumber: Int,
        state: inout DocStringState
    ) -> Token? {
        let delimiter: String
        if trimmed.hasPrefix("\"\"\"") {
            delimiter = "\"\"\""
        } else if trimmed.hasPrefix("```") {
            delimiter = "```"
        } else {
            return nil
        }
        let mediaType = String(trimmed.dropFirst(3)).trimmingCharacters(in: .whitespaces)
        let col = columnOf(firstNonWhitespace: lineStr)
        state.active = true
        state.delimiter = delimiter
        state.indent = col - 1
        return Token(
            type: .docString,
            location: Location(line: lineNumber, column: col),
            keyword: delimiter,
            text: mediaType
        )
    }

    // MARK: - Private Helpers

    /// Returns the 1-based column of the first non-whitespace character.
    private func columnOf(firstNonWhitespace line: String) -> Int {
        for (index, char) in line.enumerated() where !char.isWhitespace {
            return index + 1
        }
        return 1
    }

    /// Attempts to match a keyword at the start of the trimmed line.
    private func matchKeyword(line: String, trimmed: String, lineNumber: Int) -> Token? {
        let keywordGroups: [(keywords: [String], type: TokenType)] = [
            (language.feature, .feature),
            (language.rule, .rule),
            (language.background, .background),
            (language.scenarioOutline, .scenarioOutline),
            (language.scenario, .scenario),
            (language.examples, .examples)
        ]

        if let token = matchFirstStructuralKeyword(groups: keywordGroups, trimmed: trimmed, line: line, lineNumber: lineNumber) {
            return token
        }

        return matchStepKeyword(trimmed: trimmed, line: line, lineNumber: lineNumber)
    }

    /// Iterates keyword groups to find the first matching structural keyword.
    private func matchFirstStructuralKeyword(
        groups: [(keywords: [String], type: TokenType)],
        trimmed: String,
        line: String,
        lineNumber: Int
    ) -> Token? {
        for group in groups {
            for kw in group.keywords {
                if let token = matchStructuralKeyword(
                    trimmed: trimmed, line: line, keyword: kw,
                    type: group.type, lineNumber: lineNumber
                ) {
                    return token
                }
            }
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
        for (keyword, _) in sortedStepKeywords where trimmed.hasPrefix(keyword) {
            let col = columnOf(firstNonWhitespace: line)
            let rest = String(trimmed.dropFirst(keyword.count))
            return Token(
                type: .step,
                location: Location(line: lineNumber, column: col),
                keyword: keyword,
                text: rest
            )
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
