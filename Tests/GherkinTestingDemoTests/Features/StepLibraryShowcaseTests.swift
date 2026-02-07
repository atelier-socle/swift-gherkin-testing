// StepLibraryShowcaseTests.swift
// GherkinTestingDemoTests
//
// Copyright © 2026 Atelier Socle. MIT License.

import Foundation
import GherkinTesting
import Testing

// MARK: - Step Library Composition Showcase
//
// This @Feature struct is intentionally EMPTY — every step definition comes
// from the three composed step libraries. This demonstrates that @StepLibrary
// enables zero-code features: just declare the source and compose libraries.

@Feature(
    source: .file("Fixtures/en/step-libraries-showcase.feature"),
    reports: [.html],
    stepLibraries: [AuthenticationSteps.self, NavigationSteps.self, ValidationSteps.self]
)
struct StepLibraryShowcase {}
