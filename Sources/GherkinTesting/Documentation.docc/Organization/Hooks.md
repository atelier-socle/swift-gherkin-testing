# Hooks

Run setup and teardown code at feature, scenario, and step boundaries.

## Overview

Hooks execute code before and after features, scenarios, or individual steps. Use ``Before(_:tags:order:)`` and ``After(_:tags:order:)`` on static methods within your `@Feature` struct.

### Basic Usage

```swift
@Feature(source: .inline("..."))
struct LoginFeature {
    @Before(.feature)
    static func featureSetUp() async throws {
        // Runs once before all scenarios
    }

    @After(.feature)
    static func featureTearDown() async throws {
        // Runs once after all scenarios
    }

    @Before(.scenario)
    static func scenarioSetUp() async throws {
        // Runs before each scenario
    }

    @After(.scenario)
    static func scenarioTearDown() async throws {
        // Runs after each scenario
    }

    @Before(.step)
    static func stepSetUp() async throws {
        // Runs before each step
    }

    @After(.step)
    static func stepTearDown() async throws {
        // Runs after each step
    }
}
```

> Important: Hook methods **must** be `static`.

### Scopes

``HookScope`` defines when hooks execute:

| Scope | Timing |
|-------|--------|
| `.feature` | Once before/after the entire feature |
| `.scenario` | Before/after each scenario |
| `.step` | Before/after each individual step |

### Execution Order

- **Before hooks**: execute in registration order (FIFO) — first registered runs first
- **After hooks**: execute in reverse order (LIFO) — last registered runs first
- **After hooks always run**, even if the scenario or a previous hook fails

### Ordering with `order:`

Control execution priority with the `order:` parameter:

```swift
@Before(.scenario, order: 10)
static func setUp() async throws { }

@Before(.scenario, order: 20)
static func lateSetUp() async throws { }
```

Lower `order` values execute first for `@Before`. For `@After`, lower values execute last (cleanup in reverse). Hooks with the same `order` preserve their registration order.

### Conditional Hooks with `tags:`

Run hooks only for scenarios matching a tag expression:

```swift
@Before(.scenario, tags: "@smoke")
static func smokeSetUp() async throws {
    // Only runs for scenarios tagged @smoke
}
```

The `tags:` parameter accepts the same boolean expressions as ``TagFilter``: `"@smoke"`, `"@api and not @slow"`, etc.

## See Also

- <doc:TagFiltering>
- <doc:StepDefinitions>
