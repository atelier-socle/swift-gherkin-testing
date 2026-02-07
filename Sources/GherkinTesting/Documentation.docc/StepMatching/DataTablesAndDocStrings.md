# DataTables and DocStrings

Pass structured data and multi-line text to step handlers.

## Overview

Gherkin provides DataTables and DocStrings for passing rich data to steps. Gherkin Testing detects the parameter type in your step handler and automatically threads the appropriate argument.

<!-- TODO: Full article content covering:
- DataTable syntax in .feature files (| delimited rows)
- DataTable API: .headers, .dataRows, .asDictionaries, .empty
- Accessing DataTable in step handlers (table: DataTable parameter)
- DocString syntax (""" delimited blocks with optional media type)
- Accessing DocString in step handlers (body: String parameter)
- Mixed: captured args + DataTable in the same step
- StepArgument enum: .dataTable(DataTable) | .docString(String)
- Examples with assertions
-->
