# Step Libraries

Share and compose reusable step definition modules across features.

## Overview

Step libraries let you extract common step definitions into standalone, reusable modules. Annotate a struct with `@StepLibrary`, then compose it into any `@Feature` via the `stepLibraries:` parameter.

<!-- TODO: Full article content covering:
- @StepLibrary macro usage
- StepLibrary protocol
- Composing libraries via stepLibraries: parameter on @Feature
- How retyped() works: fresh instance per step invocation
- State isolation: libraries don't share state with the feature struct
- Designing stateless/self-contained library steps
- Multiple libraries in one feature
- Step priority when feature and library both define a step
- Example: AuthenticationSteps, NavigationSteps, ValidationSteps
-->
