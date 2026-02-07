# Custom Parameter Types

Register domain-specific Cucumber Expression parameter types.

## Overview

Custom parameter types extend Cucumber Expressions with domain-specific matchers. Use ``ParameterTypeDescriptor`` in ``GherkinConfiguration`` to declare types like `{color}`, `{status}`, or `{currency}` that match specific patterns in step text.

<!-- TODO: Full article content covering:
- ParameterTypeDescriptor: .type(_:matching:) and .type(_:matchingAny:)
- Registering in GherkinConfiguration.parameterTypes
- Using custom types in step expressions: {color}, {status}, etc.
- Arguments passed as String (identity transform)
- Built-in types vs custom types (built-in wins on name conflict)
- Multiple patterns for one type (.type(_:matchingAny:))
- StepSuggestion awareness of custom types
- Example: {status} matching "active|inactive|pending|banned"
- Example: {currency} matching "USD|EUR|GBP|JPY"
-->
