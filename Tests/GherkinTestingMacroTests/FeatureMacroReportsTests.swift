// FeatureMacroReportsTests.swift
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
        "Then": ThenMacro.self
    ]
}

@Suite("Feature Macro — Reports Parameter")
struct FeatureMacroReportsTests {

    @Test("@Feature with reports: generates reports parameter in FeatureExecutor call")
    func featureWithReports() {
        assertMacroExpansion(
            #"""
            @Feature(source: .inline("Feature: F\n  Scenario: A\n    Given x"), reports: [.html, .junitXML])
            struct ReportedFeature {
                @Given("x")
                func stepX() {
                }
            }
            """#,
            expandedSource: #"""
                struct ReportedFeature {
                    @Given("x")
                    func stepX() {
                    }
                }

                extension ReportedFeature: GherkinFeature {
                }

                extension ReportedFeature {
                    static var __stepDefinitions: [StepDefinition<Self>] {
                        [__stepDef_stepX]
                    }
                }

                @Suite("\(ReportedFeature.self)")
                struct ReportedFeature__GherkinTests {
                    @Test("Scenario: A")
                    func scenario_A() async throws {
                        try await FeatureExecutor<ReportedFeature>.run(
                            source: .inline("Feature: F\n  Scenario: A\n    Given x"),
                            definitions: ReportedFeature.__stepDefinitions,
                            configuration: ReportedFeature.gherkinConfiguration,
                            scenarioFilter: "A",
                            reports: [.html, .junitXML],
                            featureFactory: { ReportedFeature() }
                        )
                    }
                }
                """#,
            macros: testMacros
        )
    }

    @Test("@Feature with reports: and custom paths generates correct expression")
    func featureWithReportsCustomPaths() {
        assertMacroExpansion(
            #"""
            @Feature(source: .inline("Feature: F\n  Scenario: A\n    Given x"), reports: [.html("out/r.html"), .junitXML])
            struct CustomReportFeature {
                @Given("x")
                func stepX() {
                }
            }
            """#,
            expandedSource: #"""
                struct CustomReportFeature {
                    @Given("x")
                    func stepX() {
                    }
                }

                extension CustomReportFeature: GherkinFeature {
                }

                extension CustomReportFeature {
                    static var __stepDefinitions: [StepDefinition<Self>] {
                        [__stepDef_stepX]
                    }
                }

                @Suite("\(CustomReportFeature.self)")
                struct CustomReportFeature__GherkinTests {
                    @Test("Scenario: A")
                    func scenario_A() async throws {
                        try await FeatureExecutor<CustomReportFeature>.run(
                            source: .inline("Feature: F\n  Scenario: A\n    Given x"),
                            definitions: CustomReportFeature.__stepDefinitions,
                            configuration: CustomReportFeature.gherkinConfiguration,
                            scenarioFilter: "A",
                            reports: [.html("out/r.html"), .junitXML],
                            featureFactory: { CustomReportFeature() }
                        )
                    }
                }
                """#,
            macros: testMacros
        )
    }

    @Test("@Feature with .file() and reports: generates reports parameter")
    func featureFileWithReports() {
        assertMacroExpansion(
            """
            @Feature(source: .file("login.feature"), reports: [.json])
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
                            reports: [.json],
                            featureFactory: { LoginFeature() }
                        )
                    }
                }
                """,
            macros: testMacros
        )
    }
}
