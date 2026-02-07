# Getting Started

Set up Gherkin Testing in your Swift project and write your first BDD test.

## Overview

This guide walks you through adding Gherkin Testing to your Swift package, creating your first `.feature` file, and implementing step definitions using Swift macros.

### Requirements

- Swift 6.2+
- Xcode 26+ or a compatible Swift toolchain
- Swift Package Manager

## Installation

Add Gherkin Testing to your `Package.swift` dependencies:

```swift
// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "MyApp",
    platforms: [.macOS(.v14), .iOS(.v17)],
    dependencies: [
        .package(
            url: "https://github.com/AtelierSocle/swift-gherkin-testing.git",
            from: "1.0.0"
        )
    ],
    targets: [
        .testTarget(
            name: "MyAppTests",
            dependencies: [
                .product(name: "GherkinTesting", package: "swift-gherkin-testing")
            ]
        )
    ]
)
```

## Quick Start: Your First Feature

The fastest way to get started is with an inline feature definition. Create a new test file in your test target:

```swift
// Tests/MyAppTests/LoginFeatureTests.swift

import GherkinTesting
import Testing

@Feature(source: .inline("""
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

    // MARK: - Hooks

    @Before(.feature)
    static func featureSetUp() async throws {
        await Task.yield()
    }

    @After(.scenario)
    static func tearDown() async throws {
        await Task.yield()
    }

    // MARK: - Step Definitions

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

### What Happens at Compile Time

The `@Feature` macro expands to:

1. **Extension**: Makes `LoginFeature` conform to ``GherkinFeature``
2. **Member**: Generates a `__stepDefinitions` property collecting all `@Given`/`@When`/`@Then`/`@And`/`@But` definitions
3. **Peer**: Generates a `LoginFeature__GherkinTests` suite with individual `@Test` methods for each scenario

You get full Xcode test navigator integration — each scenario appears as a separate test case.

## Loading Features from Files

For larger features, use `.file()` to load from a `.feature` file in your test bundle:

```swift
@Feature(source: .file("Fixtures/en/login.feature"))
struct LoginFeature {
    // Step definitions...
}
```

Make sure the fixture directory is included in your test target's resources:

```swift
.testTarget(
    name: "MyAppTests",
    dependencies: ["GherkinTesting"],
    resources: [.copy("Fixtures")]
)
```

> Note: `.file()` sources require `import Foundation` because the macro generates `Bundle.module` for resource loading.

## Using Cucumber Expressions

Step expressions support Cucumber-style placeholders for parameter extraction:

| Placeholder | Matches | Example |
|-------------|---------|---------|
| `{string}` | Quoted text (`"..."` or `'...'`) | `"alice"` |
| `{int}` | Integer | `42`, `-7` |
| `{float}` | Decimal number | `3.14`, `-0.5` |
| `{word}` | Single word (no spaces) | `active` |
| `{}` | Any text (anonymous) | anything |

```swift
@When("they add {int} items at {float} each")
func addItems(count: String, price: String) async throws {
    let n = Int(count)!
    let p = Double(price)!
    // ...
}
```

> Important: All captured arguments are passed as `String` values. Parse them in your handler as needed.

For more details, see <doc:CucumberExpressions>.

## Next Steps

- <doc:WritingFeatureFiles> — learn the full Gherkin syntax
- <doc:StepDefinitions> — master step definition patterns
- <doc:CucumberExpressions> — use advanced expression matching
- <doc:StepLibraries> — share step definitions across features
- <doc:Hooks> — set up before/after lifecycle hooks
- <doc:ReportFormats> — generate HTML, JSON, and XML reports
