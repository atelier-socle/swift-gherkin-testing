// DryRunFeatureDemoTests.swift
// GherkinTestingDemoTests
//
// Copyright © 2026 Atelier Socle. MIT License.

import GherkinTesting
import Testing

// MARK: - @Feature with Dry-Run: collect suggestions without execution

/// A `@Feature` struct with deliberately undefined steps and `dryRun: true`.
///
/// Because `gherkinConfiguration` returns `dryRun: true`, the generated
/// `@Test` method matches steps without executing handlers. Undefined steps
/// are NOT reported as test failures in dry-run mode — they are discovery-only.
@Feature(
    source: .inline(
        """
        Feature: Undefined Steps
          Scenario: Unimplemented scenario
            Given the user has 42 items
            When they add "apples" to the cart
            Then the total is 9.99
        """))
struct DryRunDemoFeature {

    /// Dry-run configuration: steps are matched but not executed.
    static var gherkinConfiguration: GherkinConfiguration {
        GherkinConfiguration(dryRun: true)
    }

    // NO step definitions — all steps are intentionally undefined.
    // In dry-run mode, this does NOT cause test failures.
}

// MARK: - Verification: Suggestions are collected

/// Verifies that dry-run mode collects step suggestions for all undefined steps
/// without causing test failures.
@Suite("Demo: @Feature with Dry-Run")
struct DryRunFeatureVerificationTests {

    @Test("Dry-run collects suggestions for all undefined steps")
    func dryRunSuggestions() async throws {
        let result = try await FeatureExecutor<DryRunDemoFeature>.run(
            source: .inline(
                """
                Feature: Undefined Steps
                  Scenario: Unimplemented scenario
                    Given the user has 42 items
                    When they add "apples" to the cart
                    Then the total is 9.99
                """),
            definitions: DryRunDemoFeature.__stepDefinitions,
            configuration: GherkinConfiguration(dryRun: true),
            featureFactory: { DryRunDemoFeature() }
        )

        // All 3 steps should be undefined with suggestions
        let suggestions = result.allSuggestions
        #expect(suggestions.count == 3, "Expected 3 suggestions for 3 undefined steps")

        // Verify suggestions contain Cucumber expression placeholders
        let expressions = suggestions.map(\.suggestedExpression)
        #expect(expressions.contains { $0.contains("{int}") })
        #expect(expressions.contains { $0.contains("{string}") })
        #expect(expressions.contains { $0.contains("{float}") })

        // Verify generated code skeletons
        for suggestion in suggestions {
            #expect(suggestion.suggestedSignature.contains("func "))
            #expect(suggestion.suggestedSignature.contains("PendingStepError"))
        }
    }
}
