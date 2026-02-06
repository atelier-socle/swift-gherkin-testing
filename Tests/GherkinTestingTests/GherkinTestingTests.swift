// GherkinTestingTests.swift
// GherkinTestingTests
//
// Copyright © 2026 Atelier Socle. MIT License.

import Testing

@testable import GherkinTesting

/// Placeholder to ensure the test target compiles.
@Suite("GherkinTesting Smoke Tests")
struct GherkinTestingSmokeTests {
    @Test("Module imports correctly")
    func moduleImports() {
        let location = Location(line: 1, column: 1)
        #expect(location.line == 1)
    }
}
