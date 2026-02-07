# Step Libraries

Share and compose reusable step definition modules across features.

## Overview

Step libraries extract common step definitions into standalone, reusable modules. Annotate a struct with ``StepLibrary()`` and compose it into any ``Feature(source:bundle:reports:stepLibraries:)`` via the `stepLibraries:` parameter.

### Defining a Step Library

```swift
import GherkinTesting
import Testing

@StepLibrary
struct AuthenticationSteps {
    let auth = MockAuthService()

    @Given("the app is launched")
    func appLaunched() async throws {
        await auth.launchApp()
        let launched = await auth.isAppLaunched
        #expect(launched)
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
}
```

The `@StepLibrary` macro generates ``StepLibrary`` protocol conformance and a `__stepDefinitions` property that collects all step definitions.

### Composing Libraries

Pass libraries to `@Feature` via `stepLibraries:`. The feature struct can be empty — all steps come from the libraries:

```swift
@Feature(
    source: .file("Fixtures/en/step-libraries-showcase.feature"),
    stepLibraries: [AuthenticationSteps.self, NavigationSteps.self, ValidationSteps.self]
)
struct StepLibraryShowcase {}
```

### State Isolation

Each library step invocation creates a **fresh instance** of the library struct via `retyped()`. This means:

- Libraries do **not** share state with the feature struct
- Libraries do **not** share state between steps
- Design library steps to be self-contained or stateless

This is intentional — it ensures library steps are safe to compose without side effects. For stateful multi-step scenarios, define steps directly in the `@Feature` struct instead.

### Multiple Libraries

When multiple libraries define steps, they are all available. If a step matches definitions from both the feature and a library, the feature's definition takes precedence.

```swift
@Feature(
    source: .inline("..."),
    stepLibraries: [AuthSteps.self, NavSteps.self]
)
struct MyFeature {
    // This overrides any matching AuthSteps definition
    @Given("the app is launched")
    func appLaunched() async throws { /* custom */ }
}
```

## See Also

- <doc:StepDefinitions>
- <doc:Hooks>
