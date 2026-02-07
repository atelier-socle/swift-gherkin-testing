# Regex Patterns

Use regular expressions for complex step matching when Cucumber Expressions are insufficient.

## Overview

For advanced step matching patterns, Gherkin Testing supports raw regular expressions as a fallback. Regex patterns have lower priority than exact matches and Cucumber Expressions, and are detected automatically from the step expression syntax.

<!-- TODO: Full article content covering:
- When to use regex vs Cucumber Expressions
- Regex syntax detection (patterns with ^, $, \d, [], etc.)
- Capture groups for parameter extraction
- Match priority: exact(0) > cucumberExpression(1) > regex(2)
- Ambiguous match handling between regex patterns
- Examples of common regex step patterns
-->
