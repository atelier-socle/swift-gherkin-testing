// SPDX-License-Identifier: Apache-2.0
//
// Copyright 2026 Atelier Socle SAS
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import SwiftSyntax
import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import Testing

@testable import GherkinTestingMacros

@Suite("SyntaxHelpers — Unit Tests")
struct SyntaxHelpersTests {

    // MARK: - replaceAll

    @Test("replaceAll replaces single occurrence")
    func replaceAllSingle() {
        let result = SyntaxHelpers.replaceAll(in: "hello world", "world", with: "swift")
        #expect(result == "hello swift")
    }

    @Test("replaceAll replaces multiple occurrences")
    func replaceAllMultiple() {
        let result = SyntaxHelpers.replaceAll(in: "a__b__c", "__", with: "_")
        #expect(result == "a_b_c")
    }

    @Test("replaceAll with no match returns original")
    func replaceAllNoMatch() {
        let result = SyntaxHelpers.replaceAll(in: "hello", "xyz", with: "abc")
        #expect(result == "hello")
    }

    @Test("replaceAll with empty target returns original")
    func replaceAllEmptyTarget() {
        let result = SyntaxHelpers.replaceAll(in: "hello", "", with: "x")
        #expect(result == "hello")
    }

    @Test("replaceAll with overlapping pattern")
    func replaceAllOverlapping() {
        let result = SyntaxHelpers.replaceAll(in: "aaa", "aa", with: "b")
        #expect(result == "ba")
    }

    // MARK: - sanitizeIdentifier

    @Test("sanitizeIdentifier replaces spaces and special chars")
    func sanitizeBasic() {
        let result = SyntaxHelpers.sanitizeIdentifier("hello world!")
        #expect(result == "hello_world")
    }

    @Test("sanitizeIdentifier collapses consecutive underscores")
    func sanitizeCollapseUnderscores() {
        let result = SyntaxHelpers.sanitizeIdentifier("a   b")
        #expect(result == "a_b")
    }

    @Test("sanitizeIdentifier trims leading/trailing underscores")
    func sanitizeTrimUnderscores() {
        let result = SyntaxHelpers.sanitizeIdentifier("_hello_")
        #expect(result == "hello")
    }

    @Test("sanitizeIdentifier prefixes digit-starting result")
    func sanitizeDigitPrefix() {
        let result = SyntaxHelpers.sanitizeIdentifier("123abc")
        #expect(result == "_123abc")
    }

    @Test("sanitizeIdentifier returns unnamed for empty input")
    func sanitizeEmpty() {
        let result = SyntaxHelpers.sanitizeIdentifier("!!!")
        #expect(result == "unnamed")
    }

    @Test("sanitizeIdentifier keeps letters, numbers, underscores")
    func sanitizeKeepsValid() {
        let result = SyntaxHelpers.sanitizeIdentifier("valid_Name_123")
        #expect(result == "valid_Name_123")
    }

    // MARK: - trimWhitespace

    @Test("trimWhitespace removes leading whitespace")
    func trimLeading() {
        let result = SyntaxHelpers.trimWhitespace("  hello")
        #expect(result == "hello")
    }

    @Test("trimWhitespace removes trailing whitespace")
    func trimTrailing() {
        let result = SyntaxHelpers.trimWhitespace("hello  ")
        #expect(result == "hello")
    }

    @Test("trimWhitespace removes tabs and newlines")
    func trimTabsNewlines() {
        let result = SyntaxHelpers.trimWhitespace("\t\nhello\n\t")
        #expect(result == "hello")
    }

    @Test("trimWhitespace on all-whitespace returns empty")
    func trimAllWhitespace() {
        let result = SyntaxHelpers.trimWhitespace("   \t\n  ")
        #expect(result == "")
    }

    // MARK: - escapeForStringLiteral

    @Test("escapeForStringLiteral escapes backslash")
    func escapeBackslash() {
        let result = SyntaxHelpers.escapeForStringLiteral("path\\to\\file")
        #expect(result == "path\\\\to\\\\file")
    }

    @Test("escapeForStringLiteral escapes carriage return")
    func escapeCarriageReturn() {
        let result = SyntaxHelpers.escapeForStringLiteral("line\rone")
        #expect(result == "line\\rone")
    }

    @Test("escapeForStringLiteral escapes tab")
    func escapeTab() {
        let result = SyntaxHelpers.escapeForStringLiteral("col\tone")
        #expect(result == "col\\tone")
    }

    @Test("escapeForStringLiteral escapes mixed special chars")
    func escapeMixed() {
        let result = SyntaxHelpers.escapeForStringLiteral("a\"b\\c\nd\re\tf")
        #expect(result == "a\\\"b\\\\c\\nd\\re\\tf")
    }

    // MARK: - extractScenarioNames

    @Test("extractScenarioNames finds scenarios with actual newlines")
    func extractScenariosWithNewlines() {
        let source = "Feature: Test\n  Scenario: Login\n    Given step\n  Scenario: Logout\n    Given step"
        let names = SyntaxHelpers.extractScenarioNames(from: source)
        #expect(names == ["Login", "Logout"])
    }

    @Test("extractScenarioNames returns empty for no scenarios")
    func extractNoScenarios() {
        let names = SyntaxHelpers.extractScenarioNames(from: "Feature: Test\n  Given step")
        #expect(names.isEmpty)
    }

    @Test("extractScenarioNames finds Scenario Outline")
    func extractScenarioOutline() {
        let source = "Feature: T\n  Scenario Outline: Parameterized\n    Given <x>"
        let names = SyntaxHelpers.extractScenarioNames(from: source)
        #expect(names == ["Parameterized"])
    }

    @Test("extractScenarioNames handles escaped newlines from string literals")
    func extractScenariosEscapedNewlines() {
        // This simulates what extractStringLiteral returns for "Feature: T\n  Scenario: X"
        let source = "Feature: T\\n  Scenario: Login\\n    Given step"
        let names = SyntaxHelpers.extractScenarioNames(from: source)
        #expect(names == ["Login"])
    }

    // MARK: - detectExpressionKind — cucumber optional and alternation

    @Test("detectExpressionKind detects cucumber optional (unescaped parentheses)")
    func detectCucumberOptional() {
        let kind = SyntaxHelpers.detectExpressionKind("I have a cat(s)")
        #expect(kind == .cucumberExpression)
    }

    @Test("detectExpressionKind detects cucumber alternation (unescaped slash)")
    func detectCucumberAlternation() {
        let kind = SyntaxHelpers.detectExpressionKind("I eat/drink water")
        #expect(kind == .cucumberExpression)
    }

    @Test("detectExpressionKind: escaped parens and slashes are NOT cucumber")
    func detectEscapedNotCucumber() {
        let kind = SyntaxHelpers.detectExpressionKind("price is 5 \\(dollars\\)")
        #expect(kind == .exact)
    }

    // MARK: - captureGroupCount edge cases

    @Test("countRegexCaptureGroups excludes non-capturing groups")
    func regexNonCapturing() {
        let count = SyntaxHelpers.captureGroupCount(in: "^(?:foo)(bar)$")
        #expect(count == 1)
    }

    @Test("countCucumberParameters with escaped brace")
    func cucumberEscapedBrace() {
        let count = SyntaxHelpers.captureGroupCount(in: "{int} \\{not a param}")
        #expect(count == 1)
    }

    // MARK: - extractStringLiteral with expression segment

    @Test("extractStringLiteral returns nil for interpolated strings")
    func extractInterpolatedString() {
        // Build a string literal with an interpolation segment
        let source: SourceFileSyntax = #"let x = "hello \(world)""#
        let stringLiterals = source.statements.compactMap { stmt -> StringLiteralExprSyntax? in
            guard let varDecl = stmt.item.as(VariableDeclSyntax.self),
                let binding = varDecl.bindings.first,
                let expr = binding.initializer?.value.as(StringLiteralExprSyntax.self)
            else { return nil }
            return expr
        }
        if let literal = stringLiterals.first {
            let result = SyntaxHelpers.extractStringLiteral(from: literal)
            #expect(result == nil)
        }
    }
}

// MARK: - Step Macro Expression Kind Tests

@Suite("Step Macros — Expression Kind Coverage")
struct StepMacroExpressionKindTests {

    private var testMacros: [String: any Macro.Type] {
        [
            "Given": GivenMacro.self,
            "When": WhenMacro.self,
            "Then": ThenMacro.self
        ]
    }

    @Test("@Given with cucumber optional expression generates cucumber pattern")
    func givenCucumberOptional() {
        assertMacroExpansion(
            """
            @Given("I have a cucumber(s)")
            func haveCucumber() {
            }
            """,
            expandedSource: """
                func haveCucumber() {
                }

                static let __stepDef_haveCucumber = StepDefinition<Self>(
                    keywordType: .context,
                    pattern: .cucumberExpression("I have a cucumber(s)"),
                    sourceLocation: Location(line: 0, column: 0),
                    handler: { _ feature, args, stepArg in feature.haveCucumber() }
                )
                """,
            macros: testMacros
        )
    }

    @Test("@When with cucumber alternation expression generates cucumber pattern")
    func whenCucumberAlternation() {
        assertMacroExpansion(
            """
            @When("I eat/drink water")
            func consume() {
            }
            """,
            expandedSource: """
                func consume() {
                }

                static let __stepDef_consume = StepDefinition<Self>(
                    keywordType: .action,
                    pattern: .cucumberExpression("I eat/drink water"),
                    sourceLocation: Location(line: 0, column: 0),
                    handler: { _ feature, args, stepArg in feature.consume() }
                )
                """,
            macros: testMacros
        )
    }

    @Test("@Given with \\s regex indicator generates regex pattern")
    func givenRegexWithWhitespace() {
        assertMacroExpansion(
            #"""
            @Given("the user enters\\s+data")
            func enterData() {
            }
            """#,
            expandedSource: #"""
                func enterData() {
                }

                static let __stepDef_enterData = StepDefinition<Self>(
                    keywordType: .context,
                    pattern: .regex("the user enters\\s+data"),
                    sourceLocation: Location(line: 0, column: 0),
                    handler: { _ feature, args, stepArg in feature.enterData() }
                )
                """#,
            macros: testMacros
        )
    }
}
