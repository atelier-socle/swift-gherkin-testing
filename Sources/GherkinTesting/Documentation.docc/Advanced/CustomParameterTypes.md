# Custom Parameter Types

Register domain-specific Cucumber Expression parameter types.

## Overview

``ParameterTypeDescriptor`` lets you declare custom parameter types like `{color}`, `{status}`, or `{currency}` in ``GherkinConfiguration``. These extend Cucumber Expressions beyond the built-in `{int}`, `{float}`, `{string}`, and `{word}` types.

### Declaring Custom Types

Use `.type(_:matching:)` with a regex pattern:

```swift
@Feature(source: .file("Fixtures/en/showcase.feature"))
struct ShowcaseFeature {
    static var gherkinConfiguration: GherkinConfiguration {
        GherkinConfiguration(
            parameterTypes: [
                .type("status", matching: "active|inactive|pending|banned"),
                .type("currency", matching: "USD|EUR|GBP|JPY")
            ]
        )
    }

    @When("they filter products by status {status}")
    func filterByStatus(status: String) async throws {
        // status = "active", "inactive", etc.
    }

    @When("they select currency {currency}")
    func selectCurrency(currency: String) async throws {
        // currency = "USD", "EUR", etc.
    }
}
```

### Multiple Patterns

Use `.type(_:matchingAny:)` for types that match several distinct patterns:

```swift
.type("date", matchingAny: [
    "\\d{4}-\\d{2}-\\d{2}",      // 2026-01-15
    "\\d{2}/\\d{2}/\\d{4}"       // 01/15/2026
])
```

### Design: String-Only Transform

Custom parameter types always match and return `String` values. There is no typed transform (e.g., returning a `Color` enum) — this keeps ``ParameterTypeDescriptor`` `Sendable` and `Equatable` without closures.

Parse the string in your step handler:

```swift
@Then("the item color should be {color}")
func checkColor(color: String) async throws {
    let myColor = Color(rawValue: color)
    #expect(myColor != nil)
}
```

### Name Conflicts

If a custom type has the same name as a built-in type (`int`, `float`, `string`, `word`), the built-in type wins. Duplicate custom type names are silently skipped.

### Step Suggestions

When dry-run mode generates step suggestions, it includes a comment listing available custom types:

```swift
// Available custom types: {status}, {currency}
```

This helps developers discover registered types when implementing new steps.

### ParameterTypeDescriptor API

```swift
public struct ParameterTypeDescriptor: Sendable, Equatable {
    public let name: String
    public let patterns: [String]

    public static func type(_ name: String, matching pattern: String) -> ParameterTypeDescriptor
    public static func type(_ name: String, matchingAny patterns: [String]) -> ParameterTypeDescriptor
}
```

## See Also

- <doc:CucumberExpressions>
- <doc:DryRunMode>
