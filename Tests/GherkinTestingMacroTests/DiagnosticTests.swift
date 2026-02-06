// DiagnosticTests.swift
// GherkinTestingMacroTests
//
// Copyright © 2026 Atelier Socle. MIT License.

import SwiftDiagnostics
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
        "And": AndMacro.self,
        "But": ButMacro.self,
        "Before": BeforeMacro.self,
        "After": AfterMacro.self,
        "StepLibrary": StepLibraryMacro.self
    ]
}

@Suite("Diagnostic Tests — Error Diagnostics")
struct DiagnosticErrorTests {

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
                    message:
                        "Step macros (@Given, @When, @Then, @And, @But) can only be applied to functions",
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
                    message:
                        "Number of function parameters must match the number of capture groups in the expression",
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
                    message:
                        "Step macros (@Given, @When, @Then, @And, @But) can only be applied to functions",
                    line: 2,
                    column: 1
                )
            ],
            macros: testMacros
        )
    }

    @Test("@And on property emits function requirement diagnostic")
    func andOnProperty() {
        assertMacroExpansion(
            """
            @And("conjunction step")
            var y = 0
            """,
            expandedSource: """
                var y = 0
                """,
            diagnostics: [
                DiagnosticSpec(
                    message:
                        "Step macros (@Given, @When, @Then, @And, @But) can only be applied to functions",
                    line: 2,
                    column: 1
                )
            ],
            macros: testMacros
        )
    }

    @Test("@But on property emits function requirement diagnostic")
    func butOnProperty() {
        assertMacroExpansion(
            """
            @But("exception step")
            var z = 0
            """,
            expandedSource: """
                var z = 0
                """,
            diagnostics: [
                DiagnosticSpec(
                    message:
                        "Step macros (@Given, @When, @Then, @And, @But) can only be applied to functions",
                    line: 2,
                    column: 1
                )
            ],
            macros: testMacros
        )
    }

    @Test("@Then with non-string literal emits diagnostic")
    func thenNonStringLiteral() {
        assertMacroExpansion(
            """
            @Then(variable)
            func check() {
            }
            """,
            expandedSource: """
                func check() {
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

    @Test("@StepLibrary on class emits struct requirement diagnostic")
    func stepLibraryOnClass() {
        assertMacroExpansion(
            """
            @StepLibrary
            class BadClass {
            }
            """,
            expandedSource: """
                class BadClass {
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

// MARK: - GherkinDiagnostic Direct Tests

@Suite("GherkinDiagnostic — Direct Coverage")
struct GherkinDiagnosticDirectTests {

    @Test("diagnosticID is unique for each case and consistent")
    func diagnosticIDAllCases() {
        let cases: [GherkinDiagnostic] = [
            .featureMissingSource, .featureInvalidSource, .featureRequiresStruct,
            .stepExpressionNotStringLiteral, .stepRequiresFunction, .stepExpressionEmpty,
            .stepParameterCountMismatch, .hookRequiresStaticFunction, .hookRequiresFunction,
            .hookInvalidScope, .stepLibraryRequiresStruct
        ]
        var ids = Set<SwiftDiagnostics.MessageID>()
        for diagnostic in cases {
            let msgID = diagnostic.diagnosticID
            ids.insert(msgID)
            // Verify consistent: calling twice returns same ID
            #expect(diagnostic.diagnosticID == msgID)
        }
        // All IDs should be unique
        #expect(ids.count == cases.count)
    }

    @Test("hookInvalidScope message is correct")
    func hookInvalidScopeMessage() {
        let diagnostic = GherkinDiagnostic.hookInvalidScope
        #expect(diagnostic.message == "Hook scope must be .feature, .scenario, or .step")
        #expect(diagnostic.severity == .error)
    }
}

@Suite("Diagnostic Tests — Code Generation")
struct DiagnosticCodeGenTests {

    @Test("Step macro with regex expression and matching params succeeds")
    func stepWithRegexExpression() {
        assertMacroExpansion(
            """
            @Given("^the user enters (.+) and (.+)$")
            func enter(a: String, b: String) {
            }
            """,
            expandedSource: """
                func enter(a: String, b: String) {
                }

                static let __stepDef_enter = StepDefinition<Self>(
                    keywordType: .context,
                    pattern: .regex("^the user enters (.+) and (.+)$"),
                    sourceLocation: Location(line: 0, column: 0),
                    handler: { feature, args in feature.enter(a: args[0], b: args[1]) }
                )
                """,
            macros: testMacros
        )
    }

    @Test("Step macro with cucumber expression generates cucumber pattern")
    func stepWithCucumberExpression() {
        assertMacroExpansion(
            """
            @When("I enter {string} and {string}")
            func enter(a: String, b: String) {
            }
            """,
            expandedSource: """
                func enter(a: String, b: String) {
                }

                static let __stepDef_enter = StepDefinition<Self>(
                    keywordType: .action,
                    pattern: .cucumberExpression("I enter {string} and {string}"),
                    sourceLocation: Location(line: 0, column: 0),
                    handler: { feature, args in feature.enter(a: args[0], b: args[1]) }
                )
                """,
            macros: testMacros
        )
    }

    @Test("Step macro with exact expression generates exact pattern")
    func stepWithExactExpression() {
        assertMacroExpansion(
            """
            @Then("the user is logged in")
            func loggedIn() {
            }
            """,
            expandedSource: """
                func loggedIn() {
                }

                static let __stepDef_loggedIn = StepDefinition<Self>(
                    keywordType: .outcome,
                    pattern: .exact("the user is logged in"),
                    sourceLocation: Location(line: 0, column: 0),
                    handler: { feature, args in feature.loggedIn() }
                )
                """,
            macros: testMacros
        )
    }

    @Test("Step macro with async throws function")
    func stepAsyncThrows() {
        assertMacroExpansion(
            """
            @Given("async step")
            func doSetup() async throws {
            }
            """,
            expandedSource: """
                func doSetup() async throws {
                }

                static let __stepDef_doSetup = StepDefinition<Self>(
                    keywordType: .context,
                    pattern: .exact("async step"),
                    sourceLocation: Location(line: 0, column: 0),
                    handler: { feature, args in try await feature.doSetup() }
                )
                """,
            macros: testMacros
        )
    }

    @Test("Step macro with _ parameter labels")
    func stepUnderscoreLabels() {
        assertMacroExpansion(
            """
            @Given("I have {int} items")
            func haveItems(_ count: String) {
            }
            """,
            expandedSource: """
                func haveItems(_ count: String) {
                }

                static let __stepDef_haveItems = StepDefinition<Self>(
                    keywordType: .context,
                    pattern: .cucumberExpression("I have {int} items"),
                    sourceLocation: Location(line: 0, column: 0),
                    handler: { feature, args in feature.haveItems(args[0]) }
                )
                """,
            macros: testMacros
        )
    }
}
