# CI Integration

Configure Gherkin Testing for continuous integration pipelines.

## Overview

Gherkin Testing integrates with CI systems through JUnit XML reports, code coverage, and standard Swift Package Manager workflows.

### GitHub Actions

A minimal workflow for build, test, and report collection:

```yaml
name: CI

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

jobs:
  build-and-test:
    runs-on: macos-26
    steps:
      - uses: actions/checkout@v4
      - name: Select Xcode
        run: sudo xcode-select -s /Applications/Xcode_26.2.app
      - name: Build
        run: swift build
      - name: Test with Coverage
        run: swift test --enable-code-coverage
      - name: Upload to Codecov
        uses: codecov/codecov-action@v5
        with:
          files: coverage.lcov
          token: ${{ secrets.CODECOV_TOKEN }}
```

### JUnit XML for CI

Most CI systems parse JUnit XML natively. Add `.junitXML` to your feature reports:

```swift
@Feature(
    source: .file("Fixtures/en/login.feature"),
    reports: [.junitXML]
)
struct LoginFeature { /* ... */ }
```

The XML is written to `/tmp/swift-gherkin-testing/reports/LoginFeature.xml` and can be collected as a build artifact:

```yaml
- name: Upload Test Reports
  uses: actions/upload-artifact@v4
  if: always()
  with:
    name: test-reports
    path: /tmp/swift-gherkin-testing/reports/
```

### Multi-Platform Builds

The project supports iOS, tvOS, watchOS, visionOS, and Mac Catalyst. Use a matrix strategy:

```yaml
platform-builds:
  runs-on: macos-26
  strategy:
    matrix:
      include:
        - platform: iOS
          destination: "generic/platform=iOS Simulator"
        - platform: tvOS
          destination: "generic/platform=tvOS Simulator"
  steps:
    - uses: actions/checkout@v4
    - name: Build for ${{ matrix.platform }}
      run: |
        xcodebuild build \
          -scheme swift-gherkin-testing \
          -destination "${{ matrix.destination }}" \
          -skipPackagePluginValidation \
          CODE_SIGNING_ALLOWED=NO
```

### Tag Filtering in CI

Run only smoke tests in PR checks, full regression on main:

```swift
static var gherkinConfiguration: GherkinConfiguration {
    let isCI = ProcessInfo.processInfo.environment["CI"] != nil
    return GherkinConfiguration(
        tagFilter: isCI ? try? TagFilter("@smoke") : nil
    )
}
```

## See Also

- <doc:ReportFormats>
- <doc:TagFiltering>
