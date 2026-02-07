# Step Definitions

Define Swift handlers for Gherkin steps using macro annotations.

## Overview

Step definitions connect Gherkin steps to Swift code. Annotate methods with ``Given(_:)``, ``When(_:)``, ``Then(_:)``, ``And(_:)``, or ``But(_:)`` to register handlers that run when a matching step is encountered.

### Basic Step Definitions

```swift
@Feature(source: .inline("""
    Feature: Login
      Scenario: Successful login
        Given the user is on the login page
        When they enter "alice" and "secret123"
        Then they should see the dashboard
        But they should not see the admin panel
    """))
struct LoginFeature {
    let auth = MockAuthService()

    @Given("the user is on the login page")
    func onLoginPage() async throws {
        await auth.navigateToLoginPage()
        let onPage = await auth.isOnLoginPage
        #expect(onPage)
    }

    @When("they enter {string} and {string}")
    func enterCredentials(username: String, password: String) async throws {
        await auth.login(username: username, password: password)
    }

    @Then("they should see the dashboard")
    func seeDashboard() async throws {
        let page = await auth.currentPage
        #expect(page == "dashboard")
    }

    @But("they should not see the admin panel")
    func noAdminPanel() async throws {
        let page = await auth.currentPage
        #expect(page != "admin")
    }
}
```

### Handler Signatures

All step handlers support `async throws`. Captured arguments from Cucumber Expressions are passed as `String` parameters:

```swift
// No parameters — exact match
@Given("the store is open")
func storeOpen() async throws { }

// Cucumber Expression parameters
@When("they add {int} items at {float} each")
func addItems(count: String, price: String) async throws { }

// DataTable parameter
@Then("the following products should be available:")
func productsAvailable(table: DataTable) async throws {
    let dicts = table.asDictionaries
    // ...
}

// DocString parameter
@When("they submit a review with:")
func submitReview(body: String) async throws { }

// Mixed: captured args + DataTable
@When("they add {int} items to the cart:")
func bulkAdd(count: String, table: DataTable) async throws { }
```

### The @Feature Macro

``Feature(source:bundle:reports:stepLibraries:)`` accepts these parameters:

| Parameter | Type | Description |
|-----------|------|-------------|
| `source:` | ``FeatureSource`` | `.inline(String)` or `.file(String)` |
| `bundle:` | `Bundle?` | Custom bundle (default: `Bundle.module`) |
| `reports:` | `[ReportFormat]` | Auto-generated reports (`.html`, `.json`, `.junitXML`) |
| `stepLibraries:` | `[any StepLibrary.Type]` | Composed step libraries |

```swift
@Feature(
    source: .file("Fixtures/en/showcase.feature"),
    reports: [.html, .json, .junitXML],
    stepLibraries: [AuthenticationSteps.self]
)
struct ShowcaseFeature { /* ... */ }
```

### Assertions

Use Swift Testing's `#expect` and `#require` for assertions inside step handlers:

```swift
@Then("the cart should contain {int} items")
func cartContains(count: String) async throws {
    let expected = Int(count) ?? 0
    let actual = await shop.cartItemCount
    #expect(actual == expected)
}
```

## See Also

- <doc:CucumberExpressions>
- <doc:DataTablesAndDocStrings>
- <doc:StepLibraries>
