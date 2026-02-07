# Regex Patterns

Use regular expressions for complex step matching.

## Overview

When Cucumber Expressions aren't expressive enough, step definitions can use raw regular expressions. The macro auto-detects regex syntax from characters like `^`, `$`, `\d`, and `[]` in the expression string.

### When to Use Regex

Prefer Cucumber Expressions for readability. Use regex when you need:

- Character classes (`[a-z]`, `\d+`)
- Quantifiers (`+`, `*`, `{2,4}`)
- Lookahead/lookbehind assertions
- Complex alternation patterns

### Regex Detection

The step macros automatically detect whether an expression is exact, Cucumber, or regex based on its content:

| Pattern Contains | Detected As |
|-----------------|-------------|
| No special chars | Exact match |
| `{type}`, `()`, `/` | Cucumber Expression |
| `^`, `$`, `\d`, `[]`, `\s` | Regular Expression |

### Capture Groups

Use parenthesized capture groups to extract parameters:

```swift
// Regex with capture groups
@Given("^the user (\\w+) has (\\d+) items$")
func userHasItems(username: String, count: String) async throws {
    // username and count extracted from capture groups
}
```

### Match Priority

Regex patterns have the lowest priority (2). If an exact match or Cucumber Expression also matches the same step text, those win:

1. **Exact** (priority 0) — `"the store is open"`
2. **Cucumber Expression** (priority 1) — `"the user has {int} items"`
3. **Regex** (priority 2) — `"^the user has (\\d+) items$"`

Two regex patterns matching the same text produce an ambiguous step error.

### StepPattern Enum

Internally, patterns are represented by ``StepPattern``:

```swift
// The three pattern kinds
StepPattern.exact("the store is open")
StepPattern.cucumberExpression("they add {int} items")
StepPattern.regex("^the user (\\w+) logged in$")
```

## See Also

- <doc:CucumberExpressions>
- <doc:StepDefinitions>
