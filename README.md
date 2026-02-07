# swift-gherkin-testing

A native BDD testing framework for Swift. Parse and execute Gherkin `.feature` files as Swift Testing tests using macros.

[![CI](https://github.com/atelier-socle/swift-gherkin-testing/actions/workflows/ci.yml/badge.svg)](https://github.com/atelier-socle/swift-gherkin-testing/actions/workflows/ci.yml)
[![codecov](https://codecov.io/github/atelier-socle/swift-gherkin-testing/graph/badge.svg?token=TF5WTJ38CA)](https://codecov.io/github/atelier-socle/swift-gherkin-testing)
[![Swift 6.2](https://img.shields.io/badge/Swift-6.2-orange.svg)](https://swift.org)
[![Platforms](https://img.shields.io/badge/Platforms-macOS%20|%20iOS%20|%20tvOS%20|%20watchOS%20|%20visionOS-blue.svg)]()

## Overview

swift-gherkin-testing integrates Gherkin BDD specifications directly into Swift Testing. Write `.feature` files or inline Gherkin, define step handlers with `@Given`/`@When`/`@Then` macros, and the framework generates native `@Suite`/`@Test` methods at compile time. Zero external runtime dependencies — only SwiftSyntax in the compiler plugin.

## Features

- **Swift Macros** — `@Feature`, `@Given`, `@When`, `@Then`, `@And`, `@But` generate test code at compile time
- **Cucumber Expressions** — `{int}`, `{float}`, `{string}`, `{word}`, alternation, optional text, custom types
- **DataTable & DocString** — step arguments threaded directly to handler parameters
- **Regex fallback** — use raw regex patterns when expressions aren't enough
- **Step Libraries** — `@StepLibrary` for reusable, composable step definitions
- **Hooks** — `@Before`/`@After` at feature, scenario, and step scope with ordering and tag filters
- **70+ languages** — full i18n from the official `gherkin-languages.json`
- **Tag filtering** — boolean expressions (`@smoke and not @slow`) to select scenarios
- **Reporters** — Cucumber JSON, JUnit XML, and standalone HTML with dark mode
- **Dry-run mode** — validate step coverage and get code suggestions without executing
- **Scenario Outline** — lazy expansion handles 1M+ examples without memory issues
- **Strict concurrency** — all public types are `Sendable`, Swift 6 concurrency safe

## Installation

Add the package to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/atelier-socle/swift-gherkin-testing.git", from: "0.1.0")
]
```

Then add the dependency to your test target:

```swift
.testTarget(
    name: "MyAppTests",
    dependencies: ["GherkinTesting"]
)
```

## Quick Start

Define a feature with inline Gherkin and implement step handlers:

```swift
import GherkinTesting
import Testing

@Feature(
    source: .inline(
        """
        @auth @smoke
        Feature: Login
          Users can log in with valid credentials.

          Background:
            Given the app is launched

          Scenario: Successful login
            Given the user is on the login page
            When they enter "alice" and "secret123"
            Then they should see the dashboard
            But they should not see the admin panel

          Scenario: Failed login with wrong password
            Given the user is on the login page
            When they enter "alice" and "wrong"
            Then they should see an error message
        """))
struct LoginFeature {
    let auth = MockAuthService()

    @Given("the app is launched")
    func appLaunched() async throws {
        await auth.launchApp()
        let launched = await auth.isAppLaunched
        #expect(launched)
    }

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

    @Then("they should see an error message")
    func seeError() async throws {
        let error = await auth.lastError
        #expect(error == "Invalid username or password")
    }

    @But("they should not see the admin panel")
    func noAdminPanel() async throws {
        let page = await auth.currentPage
        #expect(page != "admin")
    }
}
```

The `@Feature` macro generates a `@Suite` with one `@Test` per scenario. Run with `swift test` — each scenario appears as a separate test in Xcode and the command line.

## Key Concepts

### Cucumber Expressions

Step patterns use Cucumber Expressions for typed parameter extraction. Regex patterns are also supported.

```swift
// Cucumber Expression — typed parameters
@When("the user buys {int} items at {float} each")
func buy(count: Int, price: Double) async throws { }

// Regex fallback
@Then("the total should be \\$([0-9]+\\.[0-9]{2})")
func checkTotal(amount: String) async throws { }
```

### DataTable and DocString Arguments

Steps with DataTable or DocString arguments pass them directly to your handler. Declare a trailing `DataTable` or `String` parameter:

```swift
@Given("the following users exist")
func usersExist(table: DataTable) async throws {
    let headers = table.headers       // ["username", "email"]
    let dicts = table.asDictionaries  // [["username": "alice", "email": "..."], ...]
}

@When("the API receives the payload")
func apiPayload(body: String) async throws {
    // body = DocString content
}

// Mixed: captured args + trailing DataTable
@Given("I have {int} items with details")
func itemsWithTable(count: String, table: DataTable) async throws { }
```

`DataTable` provides convenience accessors: `.headers`, `.dataRows`, `.asDictionaries`, and `.empty`.

### Step Libraries

Extract reusable steps into composable libraries with `@StepLibrary`:

```swift
@StepLibrary
struct AuthenticationSteps {
    let auth = MockAuthService()

    @Given("the user is on the login page")
    func onLoginPage() async throws {
        await auth.navigateToLoginPage()
    }

    @When("they enter {string} and {string}")
    func enterCredentials(username: String, password: String) async throws {
        await auth.login(username: username, password: password)
    }
}

// Compose into a feature
@Feature(
    source: .file("login.feature"),
    stepLibraries: [AuthenticationSteps.self]
)
struct LoginFeature { }
```

### Loading .feature Files

Load features from your test bundle resources with `.file()`:

```swift
// SPM test targets (default — uses Bundle.module)
@Feature(source: .file("Features/login.feature"))
struct LoginFeature {
    // step definitions...
}

// Xcode project targets (uses Bundle.main)
@Feature(source: .file("Features/login.feature"), bundle: .main)
struct LoginFeature {
    // step definitions...
}
```

Add `.feature` files to your test target resources in `Package.swift`:

```swift
.testTarget(
    name: "MyAppTests",
    dependencies: ["GherkinTesting"],
    resources: [.copy("Features")]
)
```

### Hooks

`@Before` and `@After` hooks run at feature, scenario, or step scope. Use `order:` to control execution order and `tags:` for conditional hooks.

```swift
@Feature(source: .inline("..."))
struct MyFeature {
    @Before(.scenario, order: 10)
    static func setUp() async throws { }

    @Before(.scenario, tags: "@smoke")
    static func smokeSetUp() async throws { }

    @After(.scenario)
    static func tearDown() async throws { }
}
```

### Reporters

Generate test reports in Cucumber JSON, JUnit XML, or standalone HTML automatically after each feature execution.

```swift
// HTML and JUnit XML reports (written to /tmp/swift-gherkin-testing/reports/)
@Feature(source: .file("login.feature"), reports: [.html, .junitXML])
struct LoginFeature { ... }

// All formats at once
@Feature(source: .inline("..."), reports: ReportFormat.all)
struct FullReportFeature { ... }

// Custom output paths for CI
@Feature(source: .file("login.feature"), reports: [
    .html("reports/login.html"),
    .junitXML("reports/login.xml")
])
struct CIFeature { ... }
```

For advanced control (custom reporter instances, programmatic access), use `GherkinConfiguration` with reporter instances directly via `gherkinConfiguration`.

### Dry-Run Mode

Validate step coverage without executing handlers. Undefined steps generate code suggestions instead of test failures.

```swift
@Feature(source: .inline("..."))
struct ValidationFeature {
    static var gherkinConfiguration: GherkinConfiguration {
        GherkinConfiguration(dryRun: true)
    }
}
```

### i18n

Write features in 70+ languages. The parser detects `# language:` directives and uses localized keywords. Step definitions match by text — the pattern language is independent of the Gherkin language.

```swift
@Feature(
    source: .inline(
        """
        # language: fr
        Fonctionnalité: Authentification
          Scénario: Connexion réussie
            Soit l'application est lancée
            Quand l'utilisateur entre "alice" et "secret123"
            Alors il devrait voir le tableau de bord
        """))
struct FrenchAuthFeature {
    @Given("l'application est lancée")
    func appLaunched() async throws { }

    @When("l'utilisateur entre {string} et {string}")
    func enterCredentials(username: String, password: String) async throws { }

    @Then("il devrait voir le tableau de bord")
    func seeDashboard() async throws { }
}
```

### Tag Filtering

Filter scenarios with boolean tag expressions using `GherkinConfiguration`:

```swift
static var gherkinConfiguration: GherkinConfiguration {
    GherkinConfiguration(tagFilter: try TagFilter("@smoke and not @slow"))
}
```

Supported operators: `and`, `or`, `not`, parentheses for grouping.

## Documentation

Full documentation will be available in the DocC catalog (coming soon).

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines on how to contribute.

## License

MIT License. See [LICENSE](LICENSE) for details.

Copyright (c) 2026 Atelier Socle SAS
