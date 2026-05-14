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

import SwiftSyntaxMacros
import SwiftSyntaxMacrosGenericTestSupport
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
                    func stepX() {
                    }

                    static let __stepDef_stepX = StepDefinition<Self>(
                        keywordType: .context,
                        pattern: .exact("x"),
                        sourceLocation: Location(line: 0, column: 0),
                        handler: { feature, args, stepArg in
                            feature.stepX()
                        }
                    )

                    static var __stepDefinitions: [StepDefinition<Self>] {
                        [__stepDef_stepX]
                    }
                }

                struct ReportedFeature__GherkinTests {
                    @Test("Scenario: A")
                    func scenario_A() async throws {
                        try await FeatureExecutor<ReportedFeature>.run(
                            source: .inline("Feature: F\\n  Scenario: A\\n    Given x"),
                            definitions: ReportedFeature.__stepDefinitions,
                                        configuration: ReportedFeature.gherkinConfiguration,
                            scenarioFilter: "A",
                                        reports: [.html, .junitXML],
                            featureFactory: {
                                ReportedFeature()
                            }
                        )
                    }
                }

                extension ReportedFeature: GherkinFeature {
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
                    func stepX() {
                    }

                    static let __stepDef_stepX = StepDefinition<Self>(
                        keywordType: .context,
                        pattern: .exact("x"),
                        sourceLocation: Location(line: 0, column: 0),
                        handler: { feature, args, stepArg in
                            feature.stepX()
                        }
                    )

                    static var __stepDefinitions: [StepDefinition<Self>] {
                        [__stepDef_stepX]
                    }
                }

                struct CustomReportFeature__GherkinTests {
                    @Test("Scenario: A")
                    func scenario_A() async throws {
                        try await FeatureExecutor<CustomReportFeature>.run(
                            source: .inline("Feature: F\\n  Scenario: A\\n    Given x"),
                            definitions: CustomReportFeature.__stepDefinitions,
                                        configuration: CustomReportFeature.gherkinConfiguration,
                            scenarioFilter: "A",
                                        reports: [.html("out/r.html"), .junitXML],
                            featureFactory: {
                                CustomReportFeature()
                            }
                        )
                    }
                }

                extension CustomReportFeature: GherkinFeature {
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
            expandedSource: #"""
                struct LoginFeature {

                    static var __stepDefinitions: [StepDefinition<Self>] {
                        []
                    }
                }

                struct LoginFeature__GherkinTests {
                    @Test("Feature: LoginFeature")
                    func feature_test() async throws {
                        try await FeatureExecutor<LoginFeature>.run(
                            source: .file("login.feature"),
                            definitions: LoginFeature.__stepDefinitions,
                            bundle: Bundle.module,
                                        configuration: LoginFeature.gherkinConfiguration,
                                        reports: [.json],
                            featureFactory: {
                                LoginFeature()
                            }
                        )
                    }
                }

                extension LoginFeature: GherkinFeature {
                }
                """#,
            macros: testMacros
        )
    }
}
