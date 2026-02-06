// FeatureMacroTests.swift
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
]

@Suite("Feature Macro Expansion Tests")
struct FeatureMacroTests {

    @Test("@Feature with .file() generates single test method")
    func featureFileSource() {
        assertMacroExpansion(
            """
            @Feature(source: .file("login.feature"))
            struct LoginFeature {
            }
            """,
            expandedSource: """
            struct LoginFeature {
            }

            extension LoginFeature: GherkinFeature {
            }

            extension LoginFeature {
                static var __stepDefinitions: [StepDefinition<Self>] {
                    []
                }
            }

            @Suite("\\(LoginFeature.self)")
            struct LoginFeature__GherkinTests {
                @Test("Feature: LoginFeature")
                func feature_test() async throws {
                    try await FeatureExecutor<LoginFeature>.run(
                        source: .file("login.feature"),
                        definitions: LoginFeature.__stepDefinitions,
                        featureFactory: { LoginFeature() }
                    )
                }
            }
            """,
            macros: testMacros
        )
    }

    @Test("@Feature with .inline() and scenarios generates per-scenario tests")
    func featureInlineWithScenarios() {
        assertMacroExpansion(
            #"""
            @Feature(source: .inline("Feature: Login\n  Scenario: Successful login\n    Given logged in\n  Scenario: Failed login\n    Given not logged in"))
            struct LoginFeature {
                @Given("logged in")
                func loggedIn() {
                }
                @Given("not logged in")
                func notLoggedIn() {
                }
            }
            """#,
            expandedSource: #"""
            struct LoginFeature {
                @Given("logged in")
                func loggedIn() {
                }
                @Given("not logged in")
                func notLoggedIn() {
                }
            }

            extension LoginFeature: GherkinFeature {
            }

            extension LoginFeature {
                static var __stepDefinitions: [StepDefinition<Self>] {
                    [__stepDef_loggedIn, __stepDef_notLoggedIn]
                }
            }

            @Suite("\(LoginFeature.self)")
            struct LoginFeature__GherkinTests {
                @Test("Scenario: Successful login")
                func scenario_Successful_login() async throws {
                    try await FeatureExecutor<LoginFeature>.run(
                        source: .inline("Feature: Login\n  Scenario: Successful login\n    Given logged in\n  Scenario: Failed login\n    Given not logged in"),
                        definitions: LoginFeature.__stepDefinitions,
                        scenarioFilter: "Successful login",
                        featureFactory: { LoginFeature() }
                    )
                }

                @Test("Scenario: Failed login")
                func scenario_Failed_login() async throws {
                    try await FeatureExecutor<LoginFeature>.run(
                        source: .inline("Feature: Login\n  Scenario: Successful login\n    Given logged in\n  Scenario: Failed login\n    Given not logged in"),
                        definitions: LoginFeature.__stepDefinitions,
                        scenarioFilter: "Failed login",
                        featureFactory: { LoginFeature() }
                    )
                }
            }
            """#,
            macros: testMacros
        )
    }

    @Test("@Feature on a class emits diagnostic")
    func featureOnClassDiagnoses() {
        assertMacroExpansion(
            """
            @Feature(source: .file("test.feature"))
            class BadFeature {
            }
            """,
            expandedSource: """
            class BadFeature {
            }
            """,
            diagnostics: [
                DiagnosticSpec(message: "@Feature can only be applied to a struct", line: 1, column: 1)
            ],
            macros: testMacros
        )
    }

    @Test("@Feature without source argument emits diagnostic")
    func featureMissingSourceDiagnoses() {
        assertMacroExpansion(
            """
            @Feature
            struct BadFeature {
            }
            """,
            expandedSource: """
            struct BadFeature {
            }
            """,
            diagnostics: [
                DiagnosticSpec(
                    message: "@Feature requires a 'source:' argument, e.g. @Feature(source: .inline(\"...\"))",
                    line: 1,
                    column: 1
                )
            ],
            macros: testMacros
        )
    }
}
