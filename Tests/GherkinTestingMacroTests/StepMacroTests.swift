// StepMacroTests.swift
// GherkinTestingMacroTests
//
// Copyright © 2026 Atelier Socle. MIT License.

import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import Testing

@testable import GherkinTestingMacros

private var testMacros: [String: any Macro.Type] {
    [
        "Given": GivenMacro.self,
        "When": WhenMacro.self,
        "Then": ThenMacro.self,
        "And": AndMacro.self,
        "But": ButMacro.self
    ]
}

@Suite("Step Macro Expansion Tests")
struct StepMacroTests {

    // MARK: - @Given

    @Test("@Given with exact expression generates step definition")
    func givenExactExpression() {
        assertMacroExpansion(
            """
            @Given("the user is logged in")
            func onLoginPage() {
            }
            """,
            expandedSource: """
                func onLoginPage() {
                }

                static let __stepDef_onLoginPage = StepDefinition<Self>(
                    keywordType: .context,
                    pattern: .exact("the user is logged in"),
                    sourceLocation: Location(line: 0, column: 0),
                    handler: { _ feature, args, stepArg in feature.onLoginPage() }
                )
                """,
            macros: testMacros
        )
    }

    @Test("@Given with {string} placeholder generates cucumber expression pattern")
    func givenStringPlaceholder() {
        assertMacroExpansion(
            """
            @Given("the user enters {string}")
            func enterValue(value: String) {
            }
            """,
            expandedSource: """
                func enterValue(value: String) {
                }

                static let __stepDef_enterValue = StepDefinition<Self>(
                    keywordType: .context,
                    pattern: .cucumberExpression("the user enters {string}"),
                    sourceLocation: Location(line: 0, column: 0),
                    handler: { _ feature, args, stepArg in feature.enterValue(value: args[0]) }
                )
                """,
            macros: testMacros
        )
    }

    @Test("@Given with {int} placeholder generates cucumber expression pattern")
    func givenIntPlaceholder() {
        assertMacroExpansion(
            """
            @Given("there are {int} items")
            func items(count: String) {
            }
            """,
            expandedSource: """
                func items(count: String) {
                }

                static let __stepDef_items = StepDefinition<Self>(
                    keywordType: .context,
                    pattern: .cucumberExpression("there are {int} items"),
                    sourceLocation: Location(line: 0, column: 0),
                    handler: { _ feature, args, stepArg in feature.items(count: args[0]) }
                )
                """,
            macros: testMacros
        )
    }

    @Test("@Given with async throws function")
    func givenAsyncThrows() {
        assertMacroExpansion(
            """
            @Given("the database is ready")
            func setupDB() async throws {
            }
            """,
            expandedSource: """
                func setupDB() async throws {
                }

                static let __stepDef_setupDB = StepDefinition<Self>(
                    keywordType: .context,
                    pattern: .exact("the database is ready"),
                    sourceLocation: Location(line: 0, column: 0),
                    handler: { _ feature, args, stepArg in try await feature.setupDB() }
                )
                """,
            macros: testMacros
        )
    }

    @Test("@Given with mutating function uses feature without underscore")
    func givenMutating() {
        assertMacroExpansion(
            """
            @Given("the count is zero")
            mutating func resetCount() {
            }
            """,
            expandedSource: """
                mutating func resetCount() {
                }

                static let __stepDef_resetCount = StepDefinition<Self>(
                    keywordType: .context,
                    pattern: .exact("the count is zero"),
                    sourceLocation: Location(line: 0, column: 0),
                    handler: { feature, args, stepArg in feature.resetCount() }
                )
                """,
            macros: testMacros
        )
    }

    // MARK: - @When / @Then

    @Test("@When generates .action keyword type")
    func whenKeywordType() {
        assertMacroExpansion(
            """
            @When("the user clicks login")
            func clickLogin() {
            }
            """,
            expandedSource: """
                func clickLogin() {
                }

                static let __stepDef_clickLogin = StepDefinition<Self>(
                    keywordType: .action,
                    pattern: .exact("the user clicks login"),
                    sourceLocation: Location(line: 0, column: 0),
                    handler: { _ feature, args, stepArg in feature.clickLogin() }
                )
                """,
            macros: testMacros
        )
    }

    @Test("@Then generates .outcome keyword type")
    func thenKeywordType() {
        assertMacroExpansion(
            """
            @Then("the dashboard is visible")
            func checkDashboard() {
            }
            """,
            expandedSource: """
                func checkDashboard() {
                }

                static let __stepDef_checkDashboard = StepDefinition<Self>(
                    keywordType: .outcome,
                    pattern: .exact("the dashboard is visible"),
                    sourceLocation: Location(line: 0, column: 0),
                    handler: { _ feature, args, stepArg in feature.checkDashboard() }
                )
                """,
            macros: testMacros
        )
    }

    @Test("@And generates .conjunction keyword type")
    func andKeywordType() {
        assertMacroExpansion(
            """
            @And("the cart is empty")
            func emptyCart() {
            }
            """,
            expandedSource: """
                func emptyCart() {
                }

                static let __stepDef_emptyCart = StepDefinition<Self>(
                    keywordType: .conjunction,
                    pattern: .exact("the cart is empty"),
                    sourceLocation: Location(line: 0, column: 0),
                    handler: { _ feature, args, stepArg in feature.emptyCart() }
                )
                """,
            macros: testMacros
        )
    }

    @Test("@But generates .conjunction keyword type")
    func butKeywordType() {
        assertMacroExpansion(
            """
            @But("the user is not admin")
            func notAdmin() {
            }
            """,
            expandedSource: """
                func notAdmin() {
                }

                static let __stepDef_notAdmin = StepDefinition<Self>(
                    keywordType: .conjunction,
                    pattern: .exact("the user is not admin"),
                    sourceLocation: Location(line: 0, column: 0),
                    handler: { _ feature, args, stepArg in feature.notAdmin() }
                )
                """,
            macros: testMacros
        )
    }

    // MARK: - Multiple parameters

    @Test("@When with two {string} placeholders")
    func twoStringParams() {
        assertMacroExpansion(
            """
            @When("they enter {string} and {string}")
            func enterCredentials(username: String, password: String) {
            }
            """,
            expandedSource: """
                func enterCredentials(username: String, password: String) {
                }

                static let __stepDef_enterCredentials = StepDefinition<Self>(
                    keywordType: .action,
                    pattern: .cucumberExpression("they enter {string} and {string}"),
                    sourceLocation: Location(line: 0, column: 0),
                    handler: { _ feature, args, stepArg in feature.enterCredentials(username: args[0], password: args[1]) }
                )
                """,
            macros: testMacros
        )
    }

    @Test("@Given with underscore parameter label")
    func underscoreParam() {
        assertMacroExpansion(
            """
            @Given("there are {int} items")
            func setItems(_ count: String) {
            }
            """,
            expandedSource: """
                func setItems(_ count: String) {
                }

                static let __stepDef_setItems = StepDefinition<Self>(
                    keywordType: .context,
                    pattern: .cucumberExpression("there are {int} items"),
                    sourceLocation: Location(line: 0, column: 0),
                    handler: { _ feature, args, stepArg in feature.setItems(args[0]) }
                )
                """,
            macros: testMacros
        )
    }

}

// MARK: - DataTable and DocString Parameters

@Suite("Step Macro — DataTable & DocString Parameters")
struct StepMacroStepArgTests {

    @Test("@Given with DataTable parameter generates stepArg extraction")
    func givenWithDataTable() {
        assertMacroExpansion(
            """
            @Given("the following users exist")
            func usersExist(table: DataTable) {
            }
            """,
            expandedSource: """
                func usersExist(table: DataTable) {
                }

                static let __stepDef_usersExist = StepDefinition<Self>(
                    keywordType: .context,
                    pattern: .exact("the following users exist"),
                    sourceLocation: Location(line: 0, column: 0),
                    handler: { _ feature, args, stepArg in feature.usersExist(table: stepArg?.dataTable ?? .empty) }
                )
                """,
            macros: testMacros
        )
    }

    @Test("@When with DocString parameter generates stepArg extraction")
    func whenWithDocString() {
        assertMacroExpansion(
            """
            @When("the API receives the payload")
            func apiPayload(body: String) {
            }
            """,
            expandedSource: """
                func apiPayload(body: String) {
                }

                static let __stepDef_apiPayload = StepDefinition<Self>(
                    keywordType: .action,
                    pattern: .exact("the API receives the payload"),
                    sourceLocation: Location(line: 0, column: 0),
                    handler: { _ feature, args, stepArg in feature.apiPayload(body: stepArg?.docString ?? "") }
                )
                """,
            macros: testMacros
        )
    }

    @Test("@Given with {int} capture and trailing DataTable generates mixed args")
    func givenMixedCaptureAndDataTable() {
        assertMacroExpansion(
            """
            @Given("I have {int} items with details")
            func itemsWithTable(count: String, table: DataTable) {
            }
            """,
            expandedSource: """
                func itemsWithTable(count: String, table: DataTable) {
                }

                static let __stepDef_itemsWithTable = StepDefinition<Self>(
                    keywordType: .context,
                    pattern: .cucumberExpression("I have {int} items with details"),
                    sourceLocation: Location(line: 0, column: 0),
                    handler: { _ feature, args, stepArg in feature.itemsWithTable(count: args[0], table: stepArg?.dataTable ?? .empty) }
                )
                """,
            macros: testMacros
        )
    }

    @Test("@Given with {string} and String param does NOT trigger docString (captures match)")
    func givenStringCaptureNotDocString() {
        assertMacroExpansion(
            """
            @Given("the user enters {string}")
            func enterValue(value: String) {
            }
            """,
            expandedSource: """
                func enterValue(value: String) {
                }

                static let __stepDef_enterValue = StepDefinition<Self>(
                    keywordType: .context,
                    pattern: .cucumberExpression("the user enters {string}"),
                    sourceLocation: Location(line: 0, column: 0),
                    handler: { _ feature, args, stepArg in feature.enterValue(value: args[0]) }
                )
                """,
            macros: testMacros
        )
    }

    @Test("@Given with DataTable and underscore label omits label")
    func givenDataTableUnderscoreLabel() {
        assertMacroExpansion(
            """
            @Given("the data exists")
            func dataExists(_ table: DataTable) {
            }
            """,
            expandedSource: """
                func dataExists(_ table: DataTable) {
                }

                static let __stepDef_dataExists = StepDefinition<Self>(
                    keywordType: .context,
                    pattern: .exact("the data exists"),
                    sourceLocation: Location(line: 0, column: 0),
                    handler: { _ feature, args, stepArg in feature.dataExists(stepArg?.dataTable ?? .empty) }
                )
                """,
            macros: testMacros
        )
    }
}
