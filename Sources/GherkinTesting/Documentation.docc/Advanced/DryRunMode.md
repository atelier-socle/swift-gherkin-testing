# Dry-Run Mode

Validate step coverage without executing handlers.

## Overview

Dry-run mode processes all scenarios and checks step definitions for matches without actually executing handler code. It generates step suggestions for any undefined steps, making it useful for discovering missing step definitions early.

<!-- TODO: Full article content covering:
- Enabling dry-run via GherkinConfiguration(dryRun: true)
- Using dryRun with @Feature via gherkinConfiguration
- How dry-run processes steps (all steps, never sets scenarioFailed)
- Step suggestions for undefined steps (StepSuggestion)
- TestRunResult.allSuggestions computed property
- Dry-run issue suppression (.undefined/.ambiguous don't fail the test)
- Use cases: TDD workflow, CI validation, feature file review
-->
