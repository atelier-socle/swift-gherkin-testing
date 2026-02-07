# Tag Filtering

Include or exclude scenarios using boolean tag expressions.

## Overview

Tags let you categorize scenarios and selectively run subsets of your test suite. Gherkin Testing supports full boolean tag expressions with `and`, `or`, `not`, and parentheses.

<!-- TODO: Full article content covering:
- Tag syntax in .feature files (@tag)
- Tag inheritance: feature → rule → scenario → examples
- TagFilter configuration in GherkinConfiguration
- Boolean expressions: and, or, not, parentheses
- Operator precedence: not > and > or
- Tag-filtered scenarios produce ScenarioResult with .skipped status
- Examples: "@smoke", "@smoke and not @slow", "(@api or @ui) and @regression"
- Using tagFilter in gherkinConfiguration static property
-->
