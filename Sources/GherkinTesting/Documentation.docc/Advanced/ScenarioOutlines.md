# Scenario Outlines

Parameterize scenarios with example tables for data-driven testing.

## Overview

Scenario Outlines let you run the same scenario template with different data sets from `Examples:` tables. Combined with the ``PickleCompiler``'s lazy expansion, they scale to 100K+ examples without memory issues.

### Basic Syntax

```gherkin
@outline
Scenario Outline: Login with various credentials
  Given the customer navigates to login
  When they attempt login with "<username>" and "<password>"
  Then the login result should be "<result>"

  Examples: Valid credentials
    | username | password    | result  |
    | alice    | secret123   | success |
    | bob      | password456 | success |

  Examples: Invalid credentials
    | username | password | result              |
    | alice    | wrong    | invalid_credentials |
    | nobody   | test     | invalid_credentials |
```

Placeholders like `<username>` are replaced with values from each row.

### Tags on Examples

Each `Examples:` block can have its own tags. Tags inherit: feature + rule + scenario + examples:

```gherkin
Scenario Outline: Add product
  When they add "<product>" at <price> to the cart

  @positive
  Examples: Standard products
    | product        | price |
    | Wireless Mouse | 29.99 |

  @negative
  Examples: Edge cases
    | product     | price |
    | Free Sample | 0.00  |
```

### Placeholder Substitution

Placeholders work in step text, DataTable cells, and DocString content. Unmatched placeholders (no column in the Examples table) are left as-is.

### Compilation

``PickleCompiler`` expands each outline × examples row into a flat ``Pickle``. The expansion uses ``PickleSequence`` (a lazy `Sequence`) to avoid materializing all pickles in memory:

```swift
let compiler = PickleCompiler()
let sequence = compiler.compileSequence(document)
// Lazy — iterates one pickle at a time
for pickle in sequence {
    // Process each expanded scenario
}
```

### Performance

The lazy expansion handles large example tables efficiently. A Scenario Outline with 100+ examples (like the showcase's product/price validation) compiles and executes without lag:

```gherkin
@outline @performance
Scenario Outline: Add product with price validation
  When they add "<product>" at <price> to the cart
  Then the item "<product>" should be in the cart at <price>

  Examples: Standard products
    | product              | price  |
    | Wireless Mouse       | 29.99  |
    | USB Keyboard         | 59.99  |
    # ... 48 more rows ...

  Examples: Edge case prices
    | product              | price  |
    | Free Sample          | 0.00   |
    # ... 50 more rows ...
```

### No Examples = No Pickles

A Scenario Outline with no `Examples:` block produces zero pickles and is silently skipped.

## See Also

- <doc:WritingFeatureFiles>
- <doc:TagFiltering>
