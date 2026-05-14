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

@Suite("Feature Macro — @MainActor Isolation")
struct FeatureMacroIsolationTests {

    @Test("@MainActor struct with .inline() and scenarios generates await in featureFactory")
    func mainActorInlineWithScenarios() {
        assertMacroExpansion(
            #"""
            @MainActor
            @Feature(source: .inline("Feature: F\n  Scenario: A\n    Given x"))
            struct IsolatedFeature {
                @Given("x")
                func stepX() {
                }
            }
            """#,
            expandedSource: #"""
                @MainActor
                struct IsolatedFeature {
                    @Given("x")
                    func stepX() {
                    }
                }

                extension IsolatedFeature: GherkinFeature {
                }

                extension IsolatedFeature {
                    static var __stepDefinitions: [StepDefinition<Self>] {
                        [__stepDef_stepX]
                    }
                }

                @Suite("\(IsolatedFeature.self)")
                struct IsolatedFeature__GherkinTests {
                    @Test("Scenario: A")
                    func scenario_A() async throws {
                        try await FeatureExecutor<IsolatedFeature>.run(
                            source: .inline("Feature: F\n  Scenario: A\n    Given x"),
                            definitions: IsolatedFeature.__stepDefinitions,
                            configuration: IsolatedFeature.gherkinConfiguration,
                            scenarioFilter: "A",
                            featureFactory: { await IsolatedFeature() }
                        )
                    }
                }
                """#,
            macros: testMacros
        )
    }

    @Test("@MainActor struct with .file() generates await in featureFactory")
    func mainActorFileSource() {
        assertMacroExpansion(
            """
            @MainActor
            @Feature(source: .file("login.feature"))
            struct IsolatedFeature {
            }
            """,
            expandedSource: """
                @MainActor
                struct IsolatedFeature {
                }

                extension IsolatedFeature: GherkinFeature {
                }

                extension IsolatedFeature {
                    static var __stepDefinitions: [StepDefinition<Self>] {
                        []
                    }
                }

                @Suite("\\(IsolatedFeature.self)")
                struct IsolatedFeature__GherkinTests {
                    @Test("Feature: IsolatedFeature")
                    func feature_test() async throws {
                        try await FeatureExecutor<IsolatedFeature>.run(
                            source: .file("login.feature"),
                            definitions: IsolatedFeature.__stepDefinitions,
                            bundle: Bundle.module,
                            configuration: IsolatedFeature.gherkinConfiguration,
                            featureFactory: { await IsolatedFeature() }
                        )
                    }
                }
                """,
            macros: testMacros
        )
    }

    @Test("@MainActor struct with .inline() and no scenarios generates await in featureFactory")
    func mainActorInlineNoScenarios() {
        assertMacroExpansion(
            #"""
            @MainActor
            @Feature(source: .inline("Feature: Empty"))
            struct IsolatedFeature {
            }
            """#,
            expandedSource: #"""
                @MainActor
                struct IsolatedFeature {
                }

                extension IsolatedFeature: GherkinFeature {
                }

                extension IsolatedFeature {
                    static var __stepDefinitions: [StepDefinition<Self>] {
                        []
                    }
                }

                @Suite("\(IsolatedFeature.self)")
                struct IsolatedFeature__GherkinTests {
                    @Test("Feature: IsolatedFeature")
                    func feature_test() async throws {
                        try await FeatureExecutor<IsolatedFeature>.run(
                            source: .inline("Feature: Empty"),
                            definitions: IsolatedFeature.__stepDefinitions,
                            configuration: IsolatedFeature.gherkinConfiguration,
                            featureFactory: { await IsolatedFeature() }
                        )
                    }
                }
                """#,
            macros: testMacros
        )
    }

    @Test("@MainActor struct with hooks generates await in featureFactory alongside hooks")
    func mainActorWithHooks() {
        let input = #"""
            @MainActor
            @Feature(source: .inline("Feature: Test\n  Scenario: One\n    Given step"))
            struct IsolatedFeature {
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
            """#
        let expected = #"""
            @MainActor
            struct IsolatedFeature {
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

            extension IsolatedFeature: GherkinFeature {
            }

            extension IsolatedFeature {
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

            @Suite("\(IsolatedFeature.self)")
            struct IsolatedFeature__GherkinTests {
                @Test("Scenario: One")
                func scenario_One() async throws {
                    try await FeatureExecutor<IsolatedFeature>.run(
                        source: .inline("Feature: Test\n  Scenario: One\n    Given step"),
                        definitions: IsolatedFeature.__stepDefinitions,
                        hooks: IsolatedFeature.__hooks,
                        configuration: IsolatedFeature.gherkinConfiguration,
                        scenarioFilter: "One",
                        featureFactory: { await IsolatedFeature() }
                    )
                }
            }
            """#
        assertMacroExpansion(input, expandedSource: expected, macros: testMacros)
    }

    @Test("Struct without @MainActor generates sync featureFactory (regression)")
    func noMainActorRegressionCheck() {
        assertMacroExpansion(
            #"""
            @Feature(source: .inline("Feature: F\n  Scenario: A\n    Given x"))
            struct PlainFeature {
                @Given("x")
                func stepX() {
                }
            }
            """#,
            expandedSource: #"""
                struct PlainFeature {
                    @Given("x")
                    func stepX() {
                    }
                }

                extension PlainFeature: GherkinFeature {
                }

                extension PlainFeature {
                    static var __stepDefinitions: [StepDefinition<Self>] {
                        [__stepDef_stepX]
                    }
                }

                @Suite("\(PlainFeature.self)")
                struct PlainFeature__GherkinTests {
                    @Test("Scenario: A")
                    func scenario_A() async throws {
                        try await FeatureExecutor<PlainFeature>.run(
                            source: .inline("Feature: F\n  Scenario: A\n    Given x"),
                            definitions: PlainFeature.__stepDefinitions,
                            configuration: PlainFeature.gherkinConfiguration,
                            scenarioFilter: "A",
                            featureFactory: { PlainFeature() }
                        )
                    }
                }
                """#,
            macros: testMacros
        )
    }
}
