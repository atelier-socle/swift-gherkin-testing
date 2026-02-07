# Tag Filtering

Include or exclude scenarios using boolean tag expressions.

## Overview

``TagFilter`` evaluates boolean expressions over scenario tags, letting you run subsets of your test suite. Configure it in ``GherkinConfiguration`` via the `tagFilter:` property.

### Tag Syntax in Feature Files

```gherkin
@smoke @regression
Feature: Login
  @auth
  Scenario: Successful login
    Given ...
```

Tags inherit from parent to child: feature → rule → scenario → examples.

### Tag Expression Syntax

| Expression | Meaning |
|------------|---------|
| `@smoke` | Matches scenarios tagged `@smoke` |
| `not @wip` | Excludes `@wip` scenarios |
| `@smoke and @auth` | Both tags required |
| `@api or @ui` | Either tag matches |
| `(@api or @ui) and not @slow` | Parenthesized grouping |

Operator precedence: `not` > `and` > `or`.

### Configuration

Set `tagFilter` in your feature's `gherkinConfiguration`:

```swift
@Feature(source: .file("Fixtures/en/showcase.feature"))
struct ShowcaseFeature {
    static var gherkinConfiguration: GherkinConfiguration {
        GherkinConfiguration(
            tagFilter: try! TagFilter("@smoke and not @slow")
        )
    }
}
```

### Behavior

- Scenarios matching the filter execute normally
- Filtered-out scenarios produce a ``ScenarioResult`` with all steps set to `.skipped`
- Filtered scenarios still appear in reports (as skipped), rather than being silently dropped

### Programmatic Usage

```swift
let filter = try TagFilter("@smoke or @regression")
filter.matches(tags: ["@smoke"])           // true
filter.matches(tags: ["@regression"])      // true
filter.matches(tags: ["@wip"])             // false

let complex = try TagFilter("@api and not @slow")
complex.matches(tags: ["@api", "@fast"])   // true
complex.matches(tags: ["@api", "@slow"])   // false
```

### Error Handling

``TagFilter/init(_:)`` throws ``TagFilterError`` for invalid expressions:

- `.emptyExpression` — empty string
- `.unexpectedToken(_:position:)` — invalid syntax
- `.unexpectedEndOfExpression` — truncated expression
- `.missingClosingParenthesis` — unbalanced parentheses

## See Also

- <doc:Hooks>
- <doc:WritingFeatureFiles>
