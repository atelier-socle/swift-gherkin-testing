# Report Formats

Generate HTML, Cucumber JSON, and JUnit XML reports from test runs.

## Overview

Gherkin Testing includes three built-in reporters. Use the `reports:` parameter on `@Feature` for automatic report generation, or configure reporters programmatically via ``GherkinConfiguration``.

### Quick Setup with `reports:`

```swift
@Feature(
    source: .file("Fixtures/en/showcase.feature"),
    reports: [.html, .json, .junitXML]
)
struct ShowcaseFeature { /* ... */ }
```

Reports are written to `/tmp/swift-gherkin-testing/reports/` by default:
- `ShowcaseFeature.html`
- `ShowcaseFeature.json`
- `ShowcaseFeature.xml`

Use ``ReportFormat/all`` as a shorthand for all three formats.

### Custom Output Paths

Specify a custom path per report:

```swift
reports: [
    .html("/path/to/report.html"),
    .json("/path/to/report.json"),
    .junitXML("/path/to/report.xml")
]
```

### Built-in Reporters

| Reporter | Format | Use Case |
|----------|--------|----------|
| ``HTMLReporter`` | Standalone HTML | Human review, dark mode, tag/status filters |
| ``CucumberJSONReporter`` | Cucumber JSON | Cucumber reporting tools, dashboards |
| ``JUnitXMLReporter`` | JUnit XML | CI systems (Jenkins, GitHub Actions) |

All reporters are `actor` types for thread safety.

### Programmatic Configuration

Configure reporters via `gherkinConfiguration` for full control:

```swift
static var gherkinConfiguration: GherkinConfiguration {
    GherkinConfiguration(
        reporters: [
            CucumberJSONReporter(),
            JUnitXMLReporter(),
            HTMLReporter()
        ]
    )
}
```

### CompositeReporter

``CompositeReporter`` dispatches lifecycle events to multiple reporters:

```swift
let composite = CompositeReporter(reporters: [
    HTMLReporter(),
    JUnitXMLReporter()
])
```

### GherkinReporter Protocol

Implement ``GherkinReporter`` to create custom reporters:

```swift
public protocol GherkinReporter: Sendable {
    func featureStarted(_ feature: FeatureResult) async
    func scenarioStarted(_ scenario: ScenarioResult) async
    func stepFinished(_ step: StepResult) async
    func scenarioFinished(_ scenario: ScenarioResult) async
    func featureFinished(_ feature: FeatureResult) async
    func testRunFinished(_ result: TestRunResult) async
    func generateReport() async throws -> Data
}
```

The default extension `writeReport(to:)` handles directory creation and file writing.

## See Also

- <doc:CIIntegration>
- <doc:StepDefinitions>
