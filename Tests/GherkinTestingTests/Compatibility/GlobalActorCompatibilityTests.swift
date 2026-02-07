// GlobalActorCompatibilityTests.swift
// GherkinTestingTests
//
// Copyright © 2026 Atelier Socle. MIT License.

import GherkinTesting
import Testing

// MARK: - Cas 1: @MainActor sur le @Feature struct

@MainActor
@Feature(
    source: .inline(
        """
        Feature: MainActor Feature
          Scenario: Simple test
            Given something happens
            Then it should work
        """))
struct MainActorFeature {
    @Given("something happens")
    func something() async throws {}

    @Then("it should work")
    func itWorks() async throws {}
}

// MARK: - Cas 2: @MainActor sur des step handlers individuels

@Feature(
    source: .inline(
        """
        Feature: MainActor Steps
          Scenario: Mixed isolation
            Given a normal step
            When a main actor step happens
            Then it should work fine
        """))
struct MainActorStepsFeature {
    @MainActor
    @Given("a normal step")
    func normalStep() async throws {}

    @MainActor
    @When("a main actor step happens")
    func mainActorStep() async throws {}

    @Then("it should work fine")
    func itWorks() async throws {}
}

// MARK: - Cas 3: @MainActor sur un @StepLibrary

@MainActor
@StepLibrary
struct MainActorStepLibrary {
    @Given("a library step")
    func libraryStep() async throws {}
}

// MARK: - Cas 4: Custom @GlobalActor

@globalActor
actor CustomActor {
    static let shared = CustomActor()
}

@CustomActor
@Feature(
    source: .inline(
        """
        Feature: Custom Actor
          Scenario: Test
            Given custom actor step
        """))
struct CustomActorFeature {
    @Given("custom actor step")
    func step() async throws {}
}

// MARK: - Cas 5: Step handler qui appelle du code @MainActor

@MainActor
class UIViewModel {
    var title = "Hello"
    func updateTitle(_ newTitle: String) { title = newTitle }
}

@Feature(
    source: .inline(
        """
        Feature: Calling MainActor code
          Scenario: Update UI
            When the title is updated to "World"
            Then the title should be "World"
        """))
struct CallingMainActorFeature {
    let vm = UIViewModel()

    @When("the title is updated to {string}")
    func updateTitle(title: String) async throws {
        await vm.updateTitle(title)
    }

    @Then("the title should be {string}")
    func checkTitle(title: String) async throws {
        let actual = await vm.title
        #expect(actual == title)
    }
}
