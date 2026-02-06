// StepLibraryMacroTests.swift
// GherkinTestingMacroTests
//
// Copyright © 2026 Atelier Socle. MIT License.

import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import Testing

@testable import GherkinTestingMacros

private var testMacros: [String: any Macro.Type] {
    [
        "StepLibrary": StepLibraryMacro.self,
        "Given": GivenMacro.self,
        "When": WhenMacro.self,
        "Then": ThenMacro.self,
    ]
}

@Suite("StepLibrary Macro Expansion Tests")
struct StepLibraryMacroTests {

    @Test("@StepLibrary generates __stepDefinitions and StepLibrary conformance")
    func stepLibraryBasic() {
        assertMacroExpansion(
            """
            @StepLibrary
            struct SharedSteps {
                @Given("logged in")
                func loggedIn() {
                }
                @When("click logout")
                func clickLogout() {
                }
            }
            """,
            expandedSource: """
            struct SharedSteps {
                @Given("logged in")
                func loggedIn() {
                }
                @When("click logout")
                func clickLogout() {
                }

                static var __stepDefinitions: [StepDefinition<Self>] {
                    [__stepDef_loggedIn, __stepDef_clickLogout]
                }
            }

            extension SharedSteps: StepLibrary {
            }
            """,
            macros: testMacros
        )
    }

    @Test("@StepLibrary with no step functions generates empty array")
    func stepLibraryEmpty() {
        assertMacroExpansion(
            """
            @StepLibrary
            struct EmptySteps {
            }
            """,
            expandedSource: """
            struct EmptySteps {

                static var __stepDefinitions: [StepDefinition<Self>] {
                    []
                }
            }

            extension EmptySteps: StepLibrary {
            }
            """,
            macros: testMacros
        )
    }

    @Test("@StepLibrary on class emits diagnostic")
    func stepLibraryOnClassDiagnoses() {
        assertMacroExpansion(
            """
            @StepLibrary
            class BadLibrary {
            }
            """,
            expandedSource: """
            class BadLibrary {
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
}
