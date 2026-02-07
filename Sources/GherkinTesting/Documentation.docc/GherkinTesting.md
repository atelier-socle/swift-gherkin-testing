# ``GherkinTesting``

@Metadata {
    @DisplayName("Gherkin Testing")
}

A production-grade BDD testing framework for Swift that parses and executes Gherkin `.feature` files as native Swift tests using Swift Macros.

## Overview

**Gherkin Testing** brings the power of Cucumber-style BDD to Swift. Write your specifications in standard Gherkin syntax, then implement step definitions using Swift macros that generate native Swift Testing `@Suite` and `@Test` methods at compile time.

```swift
import GherkinTesting
import Testing

@Feature(source: .inline("""
    Feature: Login
      Scenario: Successful login
        Given the user is on the login page
        When they enter "alice" and "secret123"
        Then they should see the dashboard
    """))
struct LoginFeature {
    @Given("the user is on the login page")
    func onLoginPage() async throws { /* ... */ }

    @When("they enter {string} and {string}")
    func enterCredentials(username: String, password: String) async throws { /* ... */ }

    @Then("they should see the dashboard")
    func seeDashboard() async throws { /* ... */ }
}
```

### Key Features

- **Zero runtime dependencies** — only SwiftSyntax in the macro compiler plugin
- **Full Gherkin v6+ compliance** — Feature, Rule, Background, Scenario Outline, DataTable, DocString, Tags, Comments, 80+ languages
- **Cucumber Expressions** — `{int}`, `{float}`, `{string}`, `{word}`, optional text, alternation, custom parameter types
- **Regex fallback** — use raw regex patterns for complex step matching
- **Swift Macros** — `@Feature`, `@Given`, `@When`, `@Then`, `@And`, `@But`, `@Before`, `@After`, `@StepLibrary`
- **Hooks** — feature-level, scenario-level, and step-level lifecycle hooks with ordering and tag filtering
- **Reporters** — built-in HTML, Cucumber JSON, and JUnit XML report generation
- **Step Libraries** — composable, reusable step definition modules
- **Dry-run mode** — validate step coverage without executing handlers
- **Tag filtering** — include/exclude scenarios using boolean tag expressions
- **Internationalization** — write features in 80+ languages
- **Performance** — handles 100K+ scenario outline examples without lag

### How It Works

1. **Write** your feature specification in Gherkin syntax (`.feature` files or inline strings)
2. **Annotate** a Swift struct with `@Feature` pointing to your Gherkin source
3. **Define** step handlers with `@Given`, `@When`, `@Then`, `@And`, `@But`
4. **Run** your tests — the macros generate native Swift Testing tests at compile time

The framework coexists cleanly with Apple's Swift Testing. Your `@Feature` types generate `@Suite`/`@Test` code under the hood, and you use `#expect`/`#require` for assertions.

## Topics

### Essentials

- <doc:GettingStarted>
- <doc:WritingFeatureFiles>
- <doc:StepDefinitions>

### Step Matching

- <doc:CucumberExpressions>
- <doc:RegexPatterns>
- <doc:DataTablesAndDocStrings>

### Organization

- <doc:StepLibraries>
- <doc:Hooks>
- <doc:TagFiltering>

### Reporting

- <doc:ReportFormats>
- <doc:CIIntegration>

### Advanced

- <doc:DryRunMode>
- <doc:Internationalization>
- <doc:ScenarioOutlines>
- <doc:CustomParameterTypes>

### Migration

- <doc:FromXCTestGherkin>

### Macros

- ``Feature(source:bundle:reports:stepLibraries:)``
- ``Given(_:)``
- ``When(_:)``
- ``Then(_:)``
- ``And(_:)``
- ``But(_:)``
- ``Before(_:tags:order:)``
- ``After(_:tags:order:)``
- ``StepLibrary()``

### Protocols

- ``GherkinFeature``
- ``StepLibrary``
- ``GherkinReporter``

### Configuration

- ``GherkinConfiguration``
- ``ParameterTypeDescriptor``
- ``FeatureSource``
- ``ReportFormat``
- ``HookScope``
- ``TagFilter``

### Core Types

- ``GherkinDocument``
- ``Feature``
- ``Scenario``
- ``Step``
- ``Background``
- ``Rule``
- ``Examples``
- ``DataTable``
- ``DocString``
- ``Tag``
- ``Comment``
- ``Location``

### Execution

- ``TestRunner``
- ``StepExecutor``
- ``StepDefinition``
- ``HookRegistry``
- ``TestRunResult``
- ``FeatureResult``
- ``ScenarioResult``
- ``StepResult``
- ``StepStatus``

### Expressions

- ``CucumberExpression``
- ``ParameterType``
- ``ParameterTypeRegistry``
- ``RegexStepMatcher``

### Compilation

- ``PickleCompiler``
- ``Pickle``
- ``PickleStep``

### Reporters

- ``CucumberJSONReporter``
- ``JUnitXMLReporter``
- ``HTMLReporter``
- ``CompositeReporter``
