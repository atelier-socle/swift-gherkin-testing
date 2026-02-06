// StepSuggestionTests.swift
// GherkinTestingTests
//
// Copyright © 2026 Atelier Socle. MIT License.

import Testing
@testable import GherkinTesting

@Suite("StepSuggestion")
struct StepSuggestionTests {

    // MARK: - Pattern Analysis

    @Test("plain text has no placeholders")
    func plainText() {
        let expr = StepSuggestion.analyzePattern("the user is logged in")
        #expect(expr == "the user is logged in")
    }

    @Test("integer is replaced with {int}")
    func integerPattern() {
        let expr = StepSuggestion.analyzePattern("the user has 42 items")
        #expect(expr == "the user has {int} items")
    }

    @Test("negative integer is replaced with {int}")
    func negativeIntegerPattern() {
        let expr = StepSuggestion.analyzePattern("the balance is -100 dollars")
        #expect(expr == "the balance is {int} dollars")
    }

    @Test("float is replaced with {float}")
    func floatPattern() {
        let expr = StepSuggestion.analyzePattern("the price is 3.14 euros")
        #expect(expr == "the price is {float} euros")
    }

    @Test("negative float is replaced with {float}")
    func negativeFloatPattern() {
        let expr = StepSuggestion.analyzePattern("the temperature is -2.5 degrees")
        #expect(expr == "the temperature is {float} degrees")
    }

    @Test("double-quoted string is replaced with {string}")
    func doubleQuotedString() {
        let expr = StepSuggestion.analyzePattern("the user enters \"hello world\"")
        #expect(expr == "the user enters {string}")
    }

    @Test("single-quoted string is replaced with {string}")
    func singleQuotedString() {
        let expr = StepSuggestion.analyzePattern("the user enters 'hello world'")
        #expect(expr == "the user enters {string}")
    }

    @Test("mixed patterns: int, float, and string")
    func mixedPatterns() {
        let expr = StepSuggestion.analyzePattern("\"Alice\" has 5 items at 9.99 each")
        #expect(expr == "{string} has {int} items at {float} each")
    }

    @Test("multiple integers")
    func multipleIntegers() {
        let expr = StepSuggestion.analyzePattern("from 1 to 100")
        #expect(expr == "from {int} to {int}")
    }

    @Test("number at start of text")
    func numberAtStart() {
        let expr = StepSuggestion.analyzePattern("42 items in the cart")
        #expect(expr == "{int} items in the cart")
    }

    @Test("number at end of text")
    func numberAtEnd() {
        let expr = StepSuggestion.analyzePattern("the cart has 42")
        #expect(expr == "the cart has {int}")
    }

    @Test("unclosed quote treated as literal")
    func unclosedQuote() {
        let expr = StepSuggestion.analyzePattern("the user enters \"hello")
        #expect(expr == "the user enters \"hello")
    }

    // MARK: - Function Name Generation

    @Test("generates camelCase from plain text")
    func funcNamePlainText() {
        let name = StepSuggestion.generateFunctionName(from: "the user is logged in")
        #expect(name == "theUserIsLoggedIn")
    }

    @Test("generates camelCase with parameter types")
    func funcNameWithParams() {
        let name = StepSuggestion.generateFunctionName(from: "the user has {int} items")
        #expect(name == "theUserHasIntItems")
    }

    @Test("generates camelCase with multiple params")
    func funcNameMultipleParams() {
        let name = StepSuggestion.generateFunctionName(from: "{string} has {int} items at {float}")
        #expect(name == "stringHasIntItemsAtFloat")
    }

    @Test("empty expression produces default name")
    func funcNameEmpty() {
        let name = StepSuggestion.generateFunctionName(from: "")
        #expect(name == "pendingStep")
    }

    // MARK: - Macro Keyword

    @Test("context keyword type produces @Given")
    func keywordGiven() {
        let kw = StepSuggestion.macroKeyword(for: .context)
        #expect(kw == "Given")
    }

    @Test("action keyword type produces @When")
    func keywordWhen() {
        let kw = StepSuggestion.macroKeyword(for: .action)
        #expect(kw == "When")
    }

    @Test("outcome keyword type produces @Then")
    func keywordThen() {
        let kw = StepSuggestion.macroKeyword(for: .outcome)
        #expect(kw == "Then")
    }

    @Test("nil keyword type defaults to @Given")
    func keywordNilDefault() {
        let kw = StepSuggestion.macroKeyword(for: nil)
        #expect(kw == "Given")
    }

    @Test("conjunction keyword type defaults to @Given")
    func keywordConjunction() {
        let kw = StepSuggestion.macroKeyword(for: .conjunction)
        #expect(kw == "Given")
    }

    // MARK: - Full Suggestion

    @Test("suggest generates complete suggestion for plain text")
    func suggestPlainText() {
        let suggestion = StepSuggestion.suggest(stepText: "the user is logged in")
        #expect(suggestion.stepText == "the user is logged in")
        #expect(suggestion.suggestedExpression == "the user is logged in")
        #expect(suggestion.suggestedSignature.contains("@Given"))
        #expect(suggestion.suggestedSignature.contains("theUserIsLoggedIn"))
        #expect(suggestion.suggestedSignature.contains("PendingStepError"))
    }

    @Test("suggest generates expression with {int}")
    func suggestWithInt() {
        let suggestion = StepSuggestion.suggest(stepText: "the user has 42 items")
        #expect(suggestion.suggestedExpression == "the user has {int} items")
    }

    @Test("suggest uses When keyword for action type")
    func suggestWithKeywordType() {
        let suggestion = StepSuggestion.suggest(
            stepText: "the user clicks submit",
            keywordType: .action
        )
        #expect(suggestion.suggestedSignature.contains("@When"))
        #expect(suggestion.keywordType == .action)
    }

    @Test("suggest generates valid Swift code")
    func suggestValidSwift() {
        let suggestion = StepSuggestion.suggest(
            stepText: "\"Alice\" has 5 items at 9.99 each",
            keywordType: .context
        )
        #expect(suggestion.suggestedExpression == "{string} has {int} items at {float} each")
        #expect(suggestion.suggestedSignature.contains("func stringHasIntItemsAtFloatEach"))
        #expect(suggestion.suggestedSignature.contains("async throws"))
    }
}
