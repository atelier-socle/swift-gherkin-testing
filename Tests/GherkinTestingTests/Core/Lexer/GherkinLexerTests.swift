// GherkinLexerTests.swift
// GherkinTestingTests
//
// Copyright © 2026 Atelier Socle. MIT License.

import Testing

@testable import GherkinTesting

@Suite("GherkinLexer Tests")
struct GherkinLexerTests {

    // MARK: - Empty Input

    @Test("Empty input ends with EOF")
    func emptyInput() {
        let lexer = GherkinLexer(source: "")
        let tokens = lexer.tokenize()
        #expect(tokens.last?.type == .eof)
    }

    // MARK: - Feature Keyword

    @Test("Feature keyword is tokenized")
    func featureKeyword() {
        let lexer = GherkinLexer(source: "Feature: Login")
        let tokens = lexer.tokenize()
        #expect(tokens[0].type == .feature)
        #expect(tokens[0].keyword == "Feature")
        #expect(tokens[0].text == "Login")
    }

    // MARK: - Scenario Keywords

    @Test("Scenario keyword is tokenized")
    func scenarioKeyword() {
        let lexer = GherkinLexer(source: "  Scenario: Test case")
        let tokens = lexer.tokenize()
        #expect(tokens[0].type == .scenario)
        #expect(tokens[0].keyword == "Scenario")
        #expect(tokens[0].text == "Test case")
    }

    @Test("Scenario Outline keyword is tokenized")
    func scenarioOutlineKeyword() {
        let lexer = GherkinLexer(source: "  Scenario Outline: Parameterized")
        let tokens = lexer.tokenize()
        #expect(tokens[0].type == .scenarioOutline)
        #expect(tokens[0].keyword == "Scenario Outline")
        #expect(tokens[0].text == "Parameterized")
    }

    @Test("Scenario Template keyword is tokenized as outline")
    func scenarioTemplateKeyword() {
        let lexer = GherkinLexer(source: "  Scenario Template: Template test")
        let tokens = lexer.tokenize()
        #expect(tokens[0].type == .scenarioOutline)
        #expect(tokens[0].keyword == "Scenario Template")
    }

    // MARK: - Step Keywords

    @Test("Given keyword is tokenized")
    func givenKeyword() {
        let lexer = GherkinLexer(source: "    Given a precondition")
        let tokens = lexer.tokenize()
        #expect(tokens[0].type == .step)
        #expect(tokens[0].keyword == "Given ")
        #expect(tokens[0].text == "a precondition")
    }

    @Test("When keyword is tokenized")
    func whenKeyword() {
        let lexer = GherkinLexer(source: "    When an action happens")
        let tokens = lexer.tokenize()
        #expect(tokens[0].type == .step)
        #expect(tokens[0].keyword == "When ")
        #expect(tokens[0].text == "an action happens")
    }

    @Test("Then keyword is tokenized")
    func thenKeyword() {
        let lexer = GherkinLexer(source: "    Then the result")
        let tokens = lexer.tokenize()
        #expect(tokens[0].type == .step)
        #expect(tokens[0].keyword == "Then ")
        #expect(tokens[0].text == "the result")
    }

    @Test("And keyword is tokenized")
    func andKeyword() {
        let lexer = GherkinLexer(source: "    And something else")
        let tokens = lexer.tokenize()
        #expect(tokens[0].type == .step)
        #expect(tokens[0].keyword == "And ")
        #expect(tokens[0].text == "something else")
    }

    @Test("But keyword is tokenized")
    func butKeyword() {
        let lexer = GherkinLexer(source: "    But not this")
        let tokens = lexer.tokenize()
        #expect(tokens[0].type == .step)
        #expect(tokens[0].keyword == "But ")
        #expect(tokens[0].text == "not this")
    }

    @Test("Wildcard * keyword is tokenized")
    func wildcardKeyword() {
        let lexer = GherkinLexer(source: "    * something")
        let tokens = lexer.tokenize()
        #expect(tokens[0].type == .step)
        #expect(tokens[0].keyword == "* ")
        #expect(tokens[0].text == "something")
    }

    // MARK: - Tags

    @Test("Tag line is tokenized")
    func tagLine() {
        let lexer = GherkinLexer(source: "@smoke @login")
        let tokens = lexer.tokenize()
        #expect(tokens[0].type == .tagLine)
        #expect(tokens[0].text == "@smoke @login")
    }

    // MARK: - Comments

    @Test("Comment line is tokenized")
    func commentLine() {
        let lexer = GherkinLexer(source: "# This is a comment")
        let tokens = lexer.tokenize()
        #expect(tokens[0].type == .comment)
        #expect(tokens[0].text == "# This is a comment")
    }

    @Test("Language directive is tokenized")
    func languageDirective() {
        let lexer = GherkinLexer(source: "# language: fr")
        let tokens = lexer.tokenize()
        #expect(tokens[0].type == .language)
        #expect(tokens[0].text == "fr")
    }

    // MARK: - Table Rows

    @Test("Table row is tokenized with cells")
    func tableRow() throws {
        let lexer = GherkinLexer(source: "    | name  | email           |")
        let tokens = lexer.tokenize()
        #expect(tokens[0].type == .tableRow)
        let items = try #require(tokens[0].items)
        #expect(items.count == 2)
        #expect(items[0].value == "name")
        #expect(items[1].value == "email")
    }

    @Test("Table row with escaped pipe")
    func tableRowEscapedPipe() throws {
        let lexer = GherkinLexer(source: "    | pipe \\| char |")
        let tokens = lexer.tokenize()
        let items = try #require(tokens[0].items)
        #expect(items.count == 1)
        #expect(items[0].value == "pipe | char")
    }

    @Test("Table row with escaped newline")
    func tableRowEscapedNewline() throws {
        let lexer = GherkinLexer(source: "    | new\\nline |")
        let tokens = lexer.tokenize()
        let items = try #require(tokens[0].items)
        #expect(items[0].value == "new\nline")
    }

    @Test("Table row with escaped backslash")
    func tableRowEscapedBackslash() throws {
        let lexer = GherkinLexer(source: "    | back\\\\slash |")
        let tokens = lexer.tokenize()
        let items = try #require(tokens[0].items)
        #expect(items[0].value == "back\\slash")
    }

    // MARK: - Doc Strings

    @Test("Doc string with triple quotes")
    func docStringTripleQuotes() {
        let source = """
                \"\"\"
                content line 1
                content line 2
                \"\"\"
            """
        let lexer = GherkinLexer(source: source)
        let tokens = lexer.tokenize()

        #expect(tokens[0].type == .docString)
        #expect(tokens[0].keyword == "\"\"\"")
        #expect(tokens[1].type == .docStringContent)
        #expect(tokens[2].type == .docStringContent)
        #expect(tokens[3].type == .docString)  // closing
    }

    @Test("Doc string with backticks and media type")
    func docStringBackticksMediaType() {
        let source = """
                ```json
                {"key": "value"}
                ```
            """
        let lexer = GherkinLexer(source: source)
        let tokens = lexer.tokenize()

        #expect(tokens[0].type == .docString)
        #expect(tokens[0].keyword == "```")
        #expect(tokens[0].text == "json")
    }

    // MARK: - Empty Lines

    @Test("Empty lines are tokenized")
    func emptyLines() {
        let lexer = GherkinLexer(source: "\n\n")
        let tokens = lexer.tokenize()
        // "\n\n" splits into 3 lines (empty, empty, empty), each producing an .empty token
        #expect(tokens.filter { $0.type == .empty }.count >= 2)
        #expect(tokens.last?.type == .eof)
    }

    // MARK: - Other/Description Lines

    @Test("Description lines are tokenized as other")
    func descriptionLines() {
        let lexer = GherkinLexer(source: "  As a user I want to login")
        let tokens = lexer.tokenize()
        #expect(tokens[0].type == .other)
        #expect(tokens[0].text == "As a user I want to login")
    }

    // MARK: - Location Tracking

    @Test("Tokens have correct line numbers")
    func tokenLineNumbers() {
        let source = """
            Feature: Test
              Scenario: S1
                Given step
            """
        let lexer = GherkinLexer(source: source)
        let tokens = lexer.tokenize()

        #expect(tokens[0].location.line == 1)  // Feature
        #expect(tokens[1].location.line == 2)  // Scenario
        #expect(tokens[2].location.line == 3)  // Given
    }

    // MARK: - Background and Other Keywords

    @Test("Background keyword is tokenized")
    func backgroundKeyword() {
        let lexer = GherkinLexer(source: "  Background:")
        let tokens = lexer.tokenize()
        #expect(tokens[0].type == .background)
        #expect(tokens[0].keyword == "Background")
    }

    @Test("Rule keyword is tokenized")
    func ruleKeyword() {
        let lexer = GherkinLexer(source: "  Rule: Business rule")
        let tokens = lexer.tokenize()
        #expect(tokens[0].type == .rule)
        #expect(tokens[0].keyword == "Rule")
        #expect(tokens[0].text == "Business rule")
    }

    @Test("Examples keyword is tokenized")
    func examplesKeyword() {
        let lexer = GherkinLexer(source: "    Examples: Positive")
        let tokens = lexer.tokenize()
        #expect(tokens[0].type == .examples)
        #expect(tokens[0].keyword == "Examples")
        #expect(tokens[0].text == "Positive")
    }

    @Test("Scenarios keyword is tokenized as examples")
    func scenariosKeyword() {
        let lexer = GherkinLexer(source: "    Scenarios:")
        let tokens = lexer.tokenize()
        #expect(tokens[0].type == .examples)
        #expect(tokens[0].keyword == "Scenarios")
    }

    // MARK: - Full Feature Tokenization

    @Test("Full feature tokenization")
    func fullFeature() {
        let source = """
            @smoke
            Feature: Login
              As a user

              Background:
                Given the app is running

              Scenario: Valid login
                Given valid credentials
                When I log in
                Then I see the dashboard
            """
        let lexer = GherkinLexer(source: source)
        let tokens = lexer.tokenize()

        let types = tokens.map(\.type)
        #expect(types.contains(.tagLine))
        #expect(types.contains(.feature))
        #expect(types.contains(.background))
        #expect(types.contains(.scenario))
        #expect(types.filter { $0 == .step }.count == 4)
        #expect(types.last == .eof)
    }
}
