# Cucumber Expressions

Use Cucumber Expression placeholders to capture parameters from step text.

## Overview

``CucumberExpression`` provides readable, type-aware step matching. Expressions are compiled from the string passed to step macros and matched against Gherkin step text at runtime.

### Built-in Parameter Types

| Placeholder | Matches | Example Input | Captured Value |
|-------------|---------|---------------|----------------|
| `{int}` | Integer (including negative) | `42`, `-7` | `"42"`, `"-7"` |
| `{float}` | Decimal number | `3.14`, `.5` | `"3.14"`, `".5"` |
| `{string}` | Quoted text (`"..."` or `'...'`) | `"alice"` | `"alice"` (quotes stripped) |
| `{word}` | Single word (no spaces) | `submit` | `"submit"` |
| `{}` | Anonymous (any text) | `anything here` | `"anything here"` |

### Usage in Step Definitions

```swift
@When("they enter {string} and {string}")
func enterCredentials(username: String, password: String) async throws {
    // username = "alice", password = "secret123"
}

@Then("the cart should contain {int} items")
func cartContains(count: String) async throws {
    let n = Int(count) ?? 0
    // ...
}

@And("the cart contains {string} at {float}")
func cartProduct(product: String, price: String) async throws {
    let p = Double(price) ?? 0.0
    // ...
}
```

> Important: All captured arguments are passed as `String`. Parse them in your handler.

### Optional Text and Alternation

Cucumber Expressions support optional text with `()` and alternation with `/`:

```swift
// Optional text: matches "I have a cucumber" and "I have a cucumbers"
@Given("I have a cucumber(s)")

// Alternation: matches "I eat a banana" and "I eat an apple"
@Given("I eat a/an banana/apple")
```

### Match Priority

When multiple step definitions could match the same text, priority determines the winner:

1. **Exact match** (priority 0) — plain string, no placeholders
2. **Cucumber Expression** (priority 1) — contains `{type}` placeholders
3. **Regex** (priority 2) — raw regular expression

If two definitions share the same priority and both match, an ambiguous step error is raised.

### Custom Parameter Types

Register domain-specific types via ``GherkinConfiguration``:

```swift
static var gherkinConfiguration: GherkinConfiguration {
    GherkinConfiguration(
        parameterTypes: [
            .type("status", matching: "active|inactive|pending|banned"),
            .type("currency", matching: "USD|EUR|GBP|JPY")
        ]
    )
}

@When("they filter products by status {status}")
func filterByStatus(status: String) async throws { }
```

See <doc:CustomParameterTypes> for details.

### Programmatic Usage

```swift
let expr = try CucumberExpression("I have {int} cucumbers")
let match = try expr.match("I have 42 cucumbers")
// match?.rawArguments == ["42"]
// match?.paramTypeNames == ["int"]
```

## See Also

- <doc:RegexPatterns>
- <doc:CustomParameterTypes>
- <doc:StepDefinitions>
