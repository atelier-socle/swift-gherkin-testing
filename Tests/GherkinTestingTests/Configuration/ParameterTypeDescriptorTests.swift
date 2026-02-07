// ParameterTypeDescriptorTests.swift
// GherkinTestingTests
//
// Copyright © 2026 Atelier Socle. MIT License.

import Testing

@testable import GherkinTesting

@Suite("ParameterTypeDescriptor")
struct ParameterTypeDescriptorTests {

    // MARK: - Single Pattern

    @Test("creates descriptor with single pattern")
    func singlePattern() {
        let descriptor = ParameterTypeDescriptor.type("color", matching: "red|green|blue")
        #expect(descriptor.name == "color")
        #expect(descriptor.patterns == ["red|green|blue"])
    }

    @Test("creates descriptor with regex pattern")
    func regexPattern() {
        let descriptor = ParameterTypeDescriptor.type("amount", matching: #"\d+\.\d{2}"#)
        #expect(descriptor.name == "amount")
        #expect(descriptor.patterns == [#"\d+\.\d{2}"#])
    }

    // MARK: - Multiple Patterns

    @Test("creates descriptor with multiple patterns")
    func multiplePatterns() {
        let descriptor = ParameterTypeDescriptor.type("boolean", matchingAny: ["true|false", "yes|no"])
        #expect(descriptor.name == "boolean")
        #expect(descriptor.patterns == ["true|false", "yes|no"])
    }

    @Test("creates descriptor with empty patterns array")
    func emptyPatterns() {
        let descriptor = ParameterTypeDescriptor.type("empty", matchingAny: [])
        #expect(descriptor.name == "empty")
        #expect(descriptor.patterns.isEmpty)
    }

    // MARK: - Equatable

    @Test("equal descriptors are equal")
    func equatable() {
        let a = ParameterTypeDescriptor.type("color", matching: "red|green|blue")
        let b = ParameterTypeDescriptor.type("color", matching: "red|green|blue")
        #expect(a == b)
    }

    @Test("different names are not equal")
    func differentNames() {
        let a = ParameterTypeDescriptor.type("color", matching: "red|green|blue")
        let b = ParameterTypeDescriptor.type("shade", matching: "red|green|blue")
        #expect(a != b)
    }

    @Test("different patterns are not equal")
    func differentPatterns() {
        let a = ParameterTypeDescriptor.type("color", matching: "red|green|blue")
        let b = ParameterTypeDescriptor.type("color", matching: "red|green")
        #expect(a != b)
    }

    // MARK: - Edge Cases

    @Test("empty name is valid")
    func emptyName() {
        let descriptor = ParameterTypeDescriptor.type("", matching: ".+")
        #expect(descriptor.name == "")
        #expect(descriptor.patterns == [".+"])
    }

    @Test("name with special characters")
    func specialCharacterName() {
        let descriptor = ParameterTypeDescriptor.type("iso-date", matching: #"\d{4}-\d{2}-\d{2}"#)
        #expect(descriptor.name == "iso-date")
    }
}
