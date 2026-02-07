# Dry-Run Mode

Validate step coverage without executing handlers.

## Overview

Dry-run mode processes all scenarios, matches step definitions, and collects suggestions for undefined steps — without running any handler code. Undefined steps do not cause test failures in this mode.

### Enabling Dry-Run

Set `dryRun: true` in your feature's `gherkinConfiguration`:

```swift
@Feature(source: .inline("""
    Feature: Undefined Steps
      Scenario: Unimplemented scenario
        Given the user has 42 items
        When they add "apples" to the cart
        Then the total is 9.99
    """))
struct DryRunDemoFeature {
    static var gherkinConfiguration: GherkinConfiguration {
        GherkinConfiguration(dryRun: true)
    }

    // No step definitions — all steps are intentionally undefined.
    // In dry-run mode, this does NOT cause test failures.
}
```

### Step Suggestions

Dry-run generates ``StepSuggestion`` instances for every undefined step. Each suggestion includes:

- `stepText` — the original step text
- `suggestedExpression` — a Cucumber Expression with detected placeholders (`{int}`, `{float}`, `{string}`)
- `suggestedSignature` — a ready-to-use Swift code skeleton with `PendingStepError`
- `keywordType` — the step's keyword type (given, when, then, etc.)

### Inspecting Suggestions Programmatically

Use ``FeatureExecutor`` to run dry-run and inspect results:

```swift
let result = try await FeatureExecutor<DryRunDemoFeature>.run(
    source: .inline("..."),
    definitions: DryRunDemoFeature.__stepDefinitions,
    configuration: GherkinConfiguration(dryRun: true),
    featureFactory: { DryRunDemoFeature() }
)

let suggestions = result.allSuggestions
// suggestions.count == 3
// Each has .suggestedExpression containing {int}, {string}, {float}
// Each has .suggestedSignature with a func skeleton
```

### How It Works

- All steps are processed (dry-run never sets `scenarioFailed`)
- Defined steps are matched but their handlers are not called
- Undefined steps generate suggestions instead of errors
- `.undefined` and `.ambiguous` statuses are suppressed from test failures

### Use Cases

- **TDD workflow**: write scenarios first, discover needed step definitions
- **CI validation**: check that all steps have definitions before merging
- **Feature file review**: verify step coverage across the team

## See Also

- <doc:StepDefinitions>
- <doc:CucumberExpressions>
