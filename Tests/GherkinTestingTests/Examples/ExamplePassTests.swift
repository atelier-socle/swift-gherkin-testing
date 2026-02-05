// ExamplePassTests.swift
// GherkinTestingTests
//
// Copyright © 2026 Atelier Socle. MIT License.

import Testing
@testable import GherkinTesting

@Suite("ExamplePass Tests")
struct ExamplePassTests {

    // MARK: - Raw Value Access

    @Test("rawValue returns correct value by column name")
    func rawValueByName() throws {
        let pass = ExamplePass(headers: ["name", "age"], values: ["Alice", "30"])
        #expect(try pass.rawValue(for: "name") == "Alice")
        #expect(try pass.rawValue(for: "age") == "30")
    }

    @Test("rawValue throws columnNotFound for missing column")
    func rawValueMissing() {
        let pass = ExamplePass(headers: ["name"], values: ["Alice"])
        #expect(throws: ExamplePassError.columnNotFound("missing")) {
            try pass.rawValue(for: "missing")
        }
    }

    // MARK: - Typed Value Access

    @Test("value returns typed String")
    func typedString() throws {
        let pass = ExamplePass(headers: ["name"], values: ["Alice"])
        let result: String = try pass.value(for: "name")
        #expect(result == "Alice")
    }

    @Test("value returns typed Int")
    func typedInt() throws {
        let pass = ExamplePass(headers: ["count"], values: ["42"])
        let result: Int = try pass.value(for: "count")
        #expect(result == 42)
    }

    @Test("value returns typed Double")
    func typedDouble() throws {
        let pass = ExamplePass(headers: ["price"], values: ["3.14"])
        let result: Double = try pass.value(for: "price")
        #expect(result == 3.14)
    }

    @Test("value returns typed Bool")
    func typedBool() throws {
        let pass = ExamplePass(headers: ["active"], values: ["true"])
        let result: Bool = try pass.value(for: "active")
        #expect(result == true)
    }

    @Test("value throws conversionFailed for invalid type")
    func typedConversionFailed() {
        let pass = ExamplePass(headers: ["count"], values: ["abc"])
        #expect(throws: ExamplePassError.conversionFailed("count", "abc")) {
            let _: Int = try pass.value(for: "count")
        }
    }

    @Test("value throws columnNotFound for missing column")
    func typedColumnNotFound() {
        let pass = ExamplePass(headers: ["name"], values: ["Alice"])
        #expect(throws: ExamplePassError.columnNotFound("missing")) {
            let _: String = try pass.value(for: "missing")
        }
    }

    // MARK: - Dictionary

    @Test("dictionary maps headers to values")
    func dictionary() {
        let pass = ExamplePass(headers: ["a", "b", "c"], values: ["1", "2", "3"])
        let dict = pass.dictionary
        #expect(dict == ["a": "1", "b": "2", "c": "3"])
    }

    @Test("dictionary is empty for empty pass")
    func dictionaryEmpty() {
        let pass = ExamplePass(headers: [], values: [])
        #expect(pass.dictionary.isEmpty)
    }

    // MARK: - Equatable / Hashable

    @Test("equal passes are equal")
    func equality() {
        let a = ExamplePass(headers: ["x"], values: ["1"])
        let b = ExamplePass(headers: ["x"], values: ["1"])
        #expect(a == b)
    }

    @Test("different passes are not equal")
    func inequality() {
        let a = ExamplePass(headers: ["x"], values: ["1"])
        let b = ExamplePass(headers: ["x"], values: ["2"])
        #expect(a != b)
    }

    // MARK: - Error Descriptions

    @Test("columnNotFound error has description")
    func columnNotFoundDescription() {
        let error = ExamplePassError.columnNotFound("age")
        #expect(error.errorDescription?.contains("age") == true)
    }

    @Test("conversionFailed error has description")
    func conversionFailedDescription() {
        let error = ExamplePassError.conversionFailed("count", "abc")
        #expect(error.errorDescription?.contains("count") == true)
        #expect(error.errorDescription?.contains("abc") == true)
    }
}
