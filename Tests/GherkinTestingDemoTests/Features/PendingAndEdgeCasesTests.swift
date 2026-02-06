// PendingAndEdgeCasesTests.swift
// GherkinTestingDemoTests
//
// Copyright © 2026 Atelier Socle. MIT License.

import Foundation
import GherkinTesting
import Testing

// MARK: - @Feature Demo: Pending Steps

/// Demonstrates `PendingStepError` thrown from a step handler.
///
/// When a handler throws `PendingStepError`, the step is marked `.pending`
/// (not `.failed`), and subsequent steps are `.skipped`. Since `.pending`
/// does not trigger `Issue.record()`, the @Feature test passes silently.
@Feature(
    source: .inline(
        """
        Feature: Pending Steps
          Scenario: Work in progress
            Given a working setup step
            When a pending action is attempted
            Then this step is skipped automatically
        """))
struct PendingStepFeature {
    @Given("a working setup step")
    func workingStep() async throws {
        await Task.yield()
    }

    @When("a pending action is attempted")
    func pendingAction() async throws {
        throw PendingStepError("Not yet implemented")
    }

    @Then("this step is skipped automatically")
    func skippedStep() async throws {
        await Task.yield()
    }
}

/// Verification: proves that PendingStepError produces `.pending` status.
@Suite("Demo: Pending Step Verification")
struct PendingStepVerificationTests {

    @Test("PendingStepError results in pending status")
    func pendingStatus() async throws {
        let result = try await FeatureExecutor<PendingStepFeature>.run(
            source: .inline(
                """
                Feature: Pending Steps
                  Scenario: Work in progress
                    Given a working setup step
                    When a pending action is attempted
                    Then this step is skipped automatically
                """),
            definitions: PendingStepFeature.__stepDefinitions,
            featureFactory: { PendingStepFeature() }
        )

        let scenario = try #require(result.featureResults.first?.scenarioResults.first)
        #expect(scenario.stepResults.count == 3)
        #expect(scenario.stepResults[0].status == .passed)
        #expect(scenario.stepResults[1].status == .pending)
        #expect(scenario.stepResults[2].status == .skipped)
    }
}

// MARK: - @Feature Demo: Ambiguous Step Detection

/// Demonstrates ambiguous step detection when two definitions match the same text.
///
/// Uses `dryRun: true` in `gherkinConfiguration` so the @Feature test passes
/// (ambiguous issues are suppressed in dry-run). The verification test confirms
/// the `.ambiguous` status is detected.
@Feature(
    source: .inline(
        """
        Feature: Ambiguous Steps
          Scenario: Two definitions match
            Given an ambiguous step
        """))
struct AmbiguousStepFeature {
    static var gherkinConfiguration: GherkinConfiguration {
        GherkinConfiguration(dryRun: true)
    }

    @Given("an ambiguous step")
    func ambiguousOne() async throws {
        await Task.yield()
    }

    @Given("an ambiguous step")
    func ambiguousTwo() async throws {
        await Task.yield()
    }
}

/// Verification: proves that ambiguous steps are detected.
@Suite("Demo: Ambiguous Step Verification")
struct AmbiguousStepVerificationTests {

    @Test("Two matching definitions produce ambiguous status")
    func ambiguousStatus() async throws {
        let result = try await FeatureExecutor<AmbiguousStepFeature>.run(
            source: .inline(
                """
                Feature: Ambiguous Steps
                  Scenario: Two definitions match
                    Given an ambiguous step
                """),
            definitions: AmbiguousStepFeature.__stepDefinitions,
            configuration: GherkinConfiguration(dryRun: true),
            featureFactory: { AmbiguousStepFeature() }
        )

        let scenario = try #require(result.featureResults.first?.scenarioResults.first)
        #expect(scenario.stepResults.count == 1)
        #expect(scenario.stepResults[0].status == .ambiguous)
    }
}

// MARK: - @Feature Demo: Regex Step Pattern

/// Demonstrates regex patterns in step definitions.
///
/// The expression starts with `^` which triggers regex detection in the macro.
/// Capture groups `(\w+)` and `(\d+)` extract typed parameters.
/// Uses raw string literal `#"..."#` to avoid double-escaping backslashes.
@Feature(
    source: .inline(
        """
        Feature: Regex Patterns
          Scenario: Match with regex
            Given the user alice is 30 years old
            Then the user info is correct
        """))
struct RegexPatternFeature {
    @Given(#"^the user (\w+) is (\d+) years old$"#)
    func userAge(name: String, age: String) async throws {
        #expect(name == "alice")
        let ageValue = try #require(Int(age))
        #expect(ageValue == 30)
    }

    @Then("the user info is correct")
    func infoCorrect() async throws {
        await Task.yield()
    }
}

// MARK: - @Feature Demo: Anonymous Cucumber Expression Parameter

/// Demonstrates the anonymous `{}` parameter type in Cucumber expressions.
///
/// `{}` matches any text (equivalent to `(.+)` regex) and captures it
/// as an anonymous string argument without a named type.
@Feature(
    source: .inline(
        """
        Feature: Anonymous Parameters
          Scenario: Capture anonymous param
            Given the red basket is ready
            Then the basket color is confirmed
        """))
struct AnonymousParamFeature {
    @Given("the {} basket is ready")
    func basketReady(color: String) async throws {
        #expect(color == "red")
    }

    @Then("the basket color is confirmed")
    func colorConfirmed() async throws {
        await Task.yield()
    }
}
