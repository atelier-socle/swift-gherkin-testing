# DataTables and DocStrings

Pass structured data and multi-line text to step handlers.

## Overview

Gherkin supports ``DataTable`` (pipe-delimited rows) and DocStrings (triple-quoted blocks) as step arguments. Gherkin Testing detects the parameter type in your handler and threads the argument automatically.

### DataTable

In your `.feature` file, attach a table directly after a step:

```gherkin
Then the following products should be available:
  | name           | price | status |
  | Wireless Mouse | 29.99 | active |
  | USB Keyboard   | 59.99 | active |
```

Access it in your handler with a `DataTable` parameter:

```swift
@Then("the following products should be available:")
func productsAvailable(table: DataTable) async throws {
    let dicts = table.asDictionaries
    for dict in dicts {
        let name = dict["name"] ?? ""
        let price = dict["price"] ?? ""
        #expect(!name.isEmpty)
    }
}
```

### DataTable API

| Property | Type | Description |
|----------|------|-------------|
| `rows` | `[TableRow]` | All rows including header |
| `headers` | `[String]` | First row cell values |
| `dataRows` | `[TableRow]` | All rows except the header |
| `asDictionaries` | `[[String: String]]` | Each data row as a header-keyed dictionary |
| `empty` | `DataTable` | Static empty table |

### DocString

Attach a triple-quoted block after a step:

```gherkin
When they submit a review for "Mouse" with:
  """json
  {
    "rating": 5,
    "title": "Excellent mouse!"
  }
  """
```

Access it as a `String` parameter in your handler:

```swift
@When("they submit a review for {string} with:")
func submitReview(product: String, body: String) async throws {
    await shop.submitReview(product: product, body: body)
}
```

The DocString content (without delimiters) is passed as a plain `String`.

### Mixed: Captured Args + DataTable

Combine Cucumber Expression captures with a DataTable:

```swift
@When("they add {int} items to the cart:")
func bulkAdd(count: String, table: DataTable) async throws {
    let dicts = table.asDictionaries
    for dict in dicts {
        let product = dict["product"] ?? ""
        let quantity = Int(dict["quantity"] ?? "1") ?? 1
        await shop.addToCart(product: product, quantity: quantity)
    }
}
```

### StepArgument Enum

At the execution level, step arguments are represented by ``StepArgument``:

```swift
@frozen public enum StepArgument: Sendable, Equatable {
    case dataTable(DataTable)
    case docString(String)
}
```

Use the computed properties `stepArg?.dataTable` and `stepArg?.docString` for safe access.

## See Also

- <doc:StepDefinitions>
- <doc:WritingFeatureFiles>
