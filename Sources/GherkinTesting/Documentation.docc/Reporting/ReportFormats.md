# Report Formats

Generate HTML, Cucumber JSON, and JUnit XML reports from test runs.

## Overview

Gherkin Testing includes built-in reporters for the three most common BDD report formats. Use the `reports:` parameter on `@Feature` for automatic report generation, or configure reporters programmatically via ``GherkinConfiguration``.

<!-- TODO: Full article content covering:
- reports: parameter on @Feature (.html, .json, .junitXML, .all)
- Report output location (/tmp/swift-gherkin-testing/reports/)
- HTML Reporter: standalone single-file with dark mode, status filters, tag dropdown
- Cucumber JSON Reporter: compatible with Cucumber reporting tools
- JUnit XML Reporter: compatible with CI systems (Jenkins, GitHub Actions, etc.)
- CompositeReporter: dispatch to multiple reporters at once
- GherkinReporter protocol for custom reporters
- writeReport(to:) for custom output paths
- Programmatic reporter configuration via gherkinConfiguration
-->
