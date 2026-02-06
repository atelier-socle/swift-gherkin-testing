// DiagnosticTests.swift
// GherkinTestingMacroTests
//
// Copyright © 2026 Atelier Socle. MIT License.

import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import Testing

@testable import GherkinTestingMacros

private let testMacros: [String: any Macro.Type] = [
    "Feature": FeatureMacro.self,
    "Given": GivenMacro.self,
    "When": WhenMacro.self,
    "Then": ThenMacro.self,
    "And": AndMacro.self,
    "But": ButMacro.self,
    "Before": BeforeMacro.self,
    "After": AfterMacro.self,
    "StepLibrary": StepLibraryMacro.self,
]

@Suite("Diagnostic Tests")
struct DiagnosticTests {

    @Test("Step macro on property emits diagnostic")
    func stepOnProperty() {
        assertMacroExpansion(
            """
            @Given("some step")
            var x = 42
            """,
            expandedSource: """
            var x = 42
            """,
            diagnostics: [
                DiagnosticSpec(
                    message: "Step macros (@Given, @When, @Then, @And, @But) can only be applied to functions",
                    line: 2,
                    column: 1
                )
            ],
            macros: testMacros
        )
    }

    @Test("Step macro with non-string-literal expression emits diagnostic")
    func stepNonStringLiteral() {
        assertMacroExpansion(
            """
            @Given(someVariable)
            func foo() {
            }
            """,
            expandedSource: """
            func foo() {
            }
            """,
            diagnostics: [
                DiagnosticSpec(
                    message: "Step expression must be a string literal",
                    line: 1,
                    column: 1
                )
            ],
            macros: testMacros
        )
    }

    @Test("Step macro with parameter count mismatch emits diagnostic")
    func stepParamMismatch() {
        assertMacroExpansion(
            """
            @Given("they enter {string} and {string}")
            func enter(one: String) {
            }
            """,
            expandedSource: """
            func enter(one: String) {
            }
            """,
            diagnostics: [
                DiagnosticSpec(
                    message: "Number of function parameters must match the number of capture groups in the expression",
                    line: 2,
                    column: 13
                )
            ],
            macros: testMacros
        )
    }

    @Test("@Feature on enum emits struct requirement diagnostic")
    func featureOnEnum() {
        assertMacroExpansion(
            """
            @Feature(source: .file("test.feature"))
            enum BadFeature {
            }
            """,
            expandedSource: """
            enum BadFeature {
            }
            """,
            diagnostics: [
                DiagnosticSpec(
                    message: "@Feature can only be applied to a struct",
                    line: 1,
                    column: 1
                )
            ],
            macros: testMacros
        )
    }

    @Test("@Before on instance method emits static requirement diagnostic")
    func beforeInstanceMethod() {
        assertMacroExpansion(
            """
            @Before(.scenario)
            func setUp() {
            }
            """,
            expandedSource: """
            func setUp() {
            }
            """,
            diagnostics: [
                DiagnosticSpec(
                    message: "@Before/@After hooks must be applied to static functions",
                    line: 2,
                    column: 1
                )
            ],
            macros: testMacros
        )
    }

    @Test("@After on instance method emits static requirement diagnostic")
    func afterInstanceMethod() {
        assertMacroExpansion(
            """
            @After(.feature)
            func tearDown() {
            }
            """,
            expandedSource: """
            func tearDown() {
            }
            """,
            diagnostics: [
                DiagnosticSpec(
                    message: "@Before/@After hooks must be applied to static functions",
                    line: 2,
                    column: 1
                )
            ],
            macros: testMacros
        )
    }

    @Test("@StepLibrary on enum emits struct requirement diagnostic")
    func stepLibraryOnEnum() {
        assertMacroExpansion(
            """
            @StepLibrary
            enum BadLibrary {
            }
            """,
            expandedSource: """
            enum BadLibrary {
            }
            """,
            diagnostics: [
                DiagnosticSpec(
                    message: "@StepLibrary can only be applied to a struct",
                    line: 1,
                    column: 1
                )
            ],
            macros: testMacros
        )
    }

    @Test("Step macro with empty expression emits diagnostic")
    func stepEmptyExpression() {
        assertMacroExpansion(
            """
            @Given("")
            func foo() {
            }
            """,
            expandedSource: """
            func foo() {
            }
            """,
            diagnostics: [
                DiagnosticSpec(
                    message: "Step expression must not be empty",
                    line: 1,
                    column: 1
                )
            ],
            macros: testMacros
        )
    }

    @Test("@When on a struct emits function requirement diagnostic")
    func whenOnStruct() {
        assertMacroExpansion(
            """
            @When("some action")
            struct NotAFunction {
            }
            """,
            expandedSource: """
            struct NotAFunction {
            }
            """,
            diagnostics: [
                DiagnosticSpec(
                    message: "Step macros (@Given, @When, @Then, @And, @But) can only be applied to functions",
                    line: 2,
                    column: 1
                )
            ],
            macros: testMacros
        )
    }
}
