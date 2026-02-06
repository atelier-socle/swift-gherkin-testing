// FeatureMacroTests.swift
// GherkinTestingMacroTests
//
// Copyright © 2026 Atelier Socle. MIT License.

import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import Testing

@testable import GherkinTestingMacros

private var testMacros: [String: any Macro.Type] {
    [
        "Feature": FeatureMacro.self,
        "Given": GivenMacro.self,
        "When": WhenMacro.self,
        "Then": ThenMacro.self,
        "Before": BeforeMacro.self,
        "After": AfterMacro.self
    ]
}

@Suite("Feature Macro Expansion Tests")
struct FeatureMacroTests {

    @Test("@Feature with .file() generates single test method with Bundle.module")
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
                            bundle: Bundle.module,
                            configuration: LoginFeature.gherkinConfiguration,
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
            @Feature(source: .inline("Feature: F\n  Scenario: A\n    Given x\n  Scenario: B\n    Given y"))
            struct LoginFeature {
                @Given("x")
                func stepX() {
                }
                @Given("y")
                func stepY() {
                }
            }
            """#,
            expandedSource: #"""
                struct LoginFeature {
                    @Given("x")
                    func stepX() {
                    }
                    @Given("y")
                    func stepY() {
                    }
                }

                extension LoginFeature: GherkinFeature {
                }

                extension LoginFeature {
                    static var __stepDefinitions: [StepDefinition<Self>] {
                        [__stepDef_stepX, __stepDef_stepY]
                    }
                }

                @Suite("\(LoginFeature.self)")
                struct LoginFeature__GherkinTests {
                    @Test("Scenario: A")
                    func scenario_A() async throws {
                        try await FeatureExecutor<LoginFeature>.run(
                            source: .inline("Feature: F\n  Scenario: A\n    Given x\n  Scenario: B\n    Given y"),
                            definitions: LoginFeature.__stepDefinitions,
                            configuration: LoginFeature.gherkinConfiguration,
                            scenarioFilter: "A",
                            featureFactory: { LoginFeature() }
                        )
                    }

                    @Test("Scenario: B")
                    func scenario_B() async throws {
                        try await FeatureExecutor<LoginFeature>.run(
                            source: .inline("Feature: F\n  Scenario: A\n    Given x\n  Scenario: B\n    Given y"),
                            definitions: LoginFeature.__stepDefinitions,
                            configuration: LoginFeature.gherkinConfiguration,
                            scenarioFilter: "B",
                            featureFactory: { LoginFeature() }
                        )
                    }
                }
                """#,
            macros: testMacros
        )
    }

    @Test("@Feature with hooks generates __hooks property and passes to executor")
    func featureWithHooks() {
        assertMacroExpansion(
            #"""
            @Feature(source: .inline("Feature: Test\n  Scenario: One\n    Given step"))
            struct HookedFeature {
                @Before(.scenario)
                static func setUp() {
                }
                @After(.scenario)
                static func tearDown() {
                }
                @Given("step")
                func step() {
                }
            }
            """#,
            expandedSource: #"""
                struct HookedFeature {
                    @Before(.scenario)
                    static func setUp() {
                    }
                    @After(.scenario)
                    static func tearDown() {
                    }
                    @Given("step")
                    func step() {
                    }
                }

                extension HookedFeature: GherkinFeature {
                }

                extension HookedFeature {
                    static var __stepDefinitions: [StepDefinition<Self>] {
                        [__stepDef_step]
                    }
                    static var __hooks: HookRegistry {
                        var registry = HookRegistry()
                        registry.addBefore(__hook_setUp)
                        registry.addAfter(__hook_tearDown)
                        return registry
                    }
                }

                @Suite("\(HookedFeature.self)")
                struct HookedFeature__GherkinTests {
                    @Test("Scenario: One")
                    func scenario_One() async throws {
                        try await FeatureExecutor<HookedFeature>.run(
                            source: .inline("Feature: Test\n  Scenario: One\n    Given step"),
                            definitions: HookedFeature.__stepDefinitions,
                            hooks: HookedFeature.__hooks,
                            configuration: HookedFeature.gherkinConfiguration,
                            scenarioFilter: "One",
                            featureFactory: { HookedFeature() }
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
