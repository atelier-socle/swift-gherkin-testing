# Hooks

Run setup and teardown code at feature, scenario, and step boundaries.

## Overview

Hooks let you execute code before and after features, scenarios, or individual steps. Use `@Before` and `@After` macros on static methods to define lifecycle hooks with optional ordering and tag-based filtering.

<!-- TODO: Full article content covering:
- @Before and @After macro usage
- HookScope: .feature, .scenario, .step
- Hook ordering with order: parameter (before ascending, after descending)
- Stable sort: same-order hooks preserve FIFO/LIFO registration order
- Tag-based conditional hooks with tags: parameter
- After hooks always run (even on failure)
- Hook methods must be static
- Use cases: database setup/teardown, screenshot on failure, logging
-->
