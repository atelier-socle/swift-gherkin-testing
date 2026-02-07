# Writing Feature Files

Learn the Gherkin syntax for describing application behavior in `.feature` files.

## Overview

Gherkin is a structured, human-readable language for specifying software behavior. Gherkin Testing supports the full Gherkin v6+ specification.

### Loading Sources

Use ``FeatureSource/inline(_:)`` for inline definitions or ``FeatureSource/file(_:)`` for external files:

```swift
// Inline — scenarios extracted at compile time
@Feature(source: .inline("""
    Feature: Login
      Scenario: Successful login
        Given the user is on the login page
    """))
struct LoginFeature { /* ... */ }

// File — parsed at runtime from Bundle.module
@Feature(source: .file("Fixtures/en/login.feature"))
struct FileLoginFeature { /* ... */ }
```

> Note: `.file()` requires `import Foundation` and `.copy("Fixtures")` in your test target's resources.

### Feature Structure

A `.feature` file starts with the `Feature:` keyword, an optional description, and contains scenarios:

```gherkin
@showcase @regression
Feature: E-Commerce Shopping Experience
  As a customer of an online store
  I want to browse products and checkout
  So that I can purchase items conveniently

  Background:
    Given the store is open
    And the product catalog is loaded

  Scenario: Browse product catalog
    When the customer views the catalog
    Then they should see at least 1 products
```

### Keywords

| Keyword | Purpose |
|---------|---------|
| `Feature:` | Declares the feature under test |
| `Background:` | Steps that run before every scenario |
| `Scenario:` | A single test case |
| `Scenario Outline:` | A parameterized scenario with `Examples:` |
| `Rule:` | Groups related scenarios (Gherkin v6+) |
| `Given` | Establishes context (precondition) |
| `When` | Describes an action |
| `Then` | Asserts an outcome |
| `And` / `But` | Continues the previous step type |
| `*` | Wildcard step (type inferred from context) |

### DataTable and DocString

Pass structured data to steps using pipe-delimited tables or triple-quoted strings:

```gherkin
Scenario: Verify catalog
  Then the following products should be available:
    | name           | price | status |
    | Wireless Mouse | 29.99 | active |
    | USB Keyboard   | 59.99 | active |

Scenario: Submit review
  When they submit a review for "Mouse" with:
    """json
    { "rating": 5, "title": "Great!" }
    """
```

### Tags

Prefix scenarios or features with `@tag` names for filtering and conditional hooks:

```gherkin
@smoke
Scenario: Quick validation
  Given something happens
```

Tags inherit from parent: feature tags apply to all scenarios, rule tags to scenarios within the rule.

### Comments and Language Directive

Lines starting with `#` are comments. The `# language:` directive sets the feature language:

```gherkin
# language: fr
Fonctionnalité: Authentification
  Scénario: Connexion réussie
    Soit l'application est lancée
```

See <doc:Internationalization> for the full list of 70+ supported languages.

## See Also

- <doc:GettingStarted>
- <doc:StepDefinitions>
- <doc:ScenarioOutlines>
- <doc:Internationalization>
