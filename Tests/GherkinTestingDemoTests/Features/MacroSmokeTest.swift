// MacroSmokeTest.swift
// GherkinTestingDemoTests
//
// Minimal end-to-end test to verify @Feature + @Given/@When/@Then macros compile and run.

import Testing
import GherkinTesting

@Feature(source: .inline("Feature: Smoke\n  Scenario: Passes\n    Given smoke step"))
struct MacroSmokeFeature {
    @Given("smoke step")
    func smokeStep() { }
}
