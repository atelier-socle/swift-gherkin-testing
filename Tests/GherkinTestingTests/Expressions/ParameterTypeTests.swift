// ParameterTypeTests.swift
// GherkinTestingTests
//
// Copyright © 2026 Atelier Socle. MIT License.

import Testing
@testable import GherkinTesting

@Suite("ParameterTypeRegistry")
struct ParameterTypeRegistryTests {

    // MARK: - Built-in Types

    @Test("registry contains int type")
    func builtInInt() throws {
        let registry = ParameterTypeRegistry()
        let intType = try #require(registry.lookup("int"))
        #expect(intType.name == "int")
        #expect(intType.regexps == [#"-?\d+"#])
        #expect(intType.preferForRegexpMatch == true)
    }

    @Test("registry contains float type")
    func builtInFloat() throws {
        let registry = ParameterTypeRegistry()
        let floatType = try #require(registry.lookup("float"))
        #expect(floatType.name == "float")
        #expect(floatType.regexps == [#"-?\d*\.\d+"#])
        #expect(floatType.preferForRegexpMatch == true)
    }

    @Test("registry contains string type")
    func builtInString() throws {
        let registry = ParameterTypeRegistry()
        let stringType = try #require(registry.lookup("string"))
        #expect(stringType.name == "string")
        #expect(stringType.regexps.count == 2)
    }

    @Test("registry contains word type")
    func builtInWord() throws {
        let registry = ParameterTypeRegistry()
        let wordType = try #require(registry.lookup("word"))
        #expect(wordType.name == "word")
        #expect(wordType.regexps == [#"[^\s]+"#])
    }

    @Test("registry contains anonymous type")
    func builtInAnonymous() throws {
        let registry = ParameterTypeRegistry()
        let anonType = try #require(registry.lookup(""))
        #expect(anonType.name == "")
        #expect(anonType.regexps == [".+"])
        #expect(anonType.useForSnippets == false)
    }

    // MARK: - String Transformer

    @Test("string transformer strips double quotes")
    func stringTransformerDoubleQuotes() throws {
        let registry = ParameterTypeRegistry()
        let stringType = try #require(registry.lookup("string"))
        let result = try stringType.transformer("\"hello world\"")
        #expect(result == "hello world")
    }

    @Test("string transformer strips single quotes")
    func stringTransformerSingleQuotes() throws {
        let registry = ParameterTypeRegistry()
        let stringType = try #require(registry.lookup("string"))
        let result = try stringType.transformer("'hello world'")
        #expect(result == "hello world")
    }

    @Test("string transformer returns unquoted text as-is")
    func stringTransformerNoQuotes() throws {
        let registry = ParameterTypeRegistry()
        let stringType = try #require(registry.lookup("string"))
        let result = try stringType.transformer("hello")
        #expect(result == "hello")
    }

    @Test("int transformer returns raw value")
    func intTransformer() throws {
        let registry = ParameterTypeRegistry()
        let intType = try #require(registry.lookup("int"))
        let result = try intType.transformer("42")
        #expect(result == "42")
    }

    @Test("float transformer returns raw value")
    func floatTransformer() throws {
        let registry = ParameterTypeRegistry()
        let floatType = try #require(registry.lookup("float"))
        let result = try floatType.transformer("3.14")
        #expect(result == "3.14")
    }

    // MARK: - Custom Type Registration

    @Test("register custom parameter type")
    func registerCustomType() throws {
        var registry = ParameterTypeRegistry()
        let colorType = ParameterType<String>(
            name: "color",
            regexps: ["red|green|blue"],
            type: String.self,
            converter: { $0 }
        )
        try registry.register(colorType)
        let looked = try #require(registry.lookup("color"))
        #expect(looked.name == "color")
        #expect(looked.regexps == ["red|green|blue"])
    }

    @Test("register duplicate name throws error")
    func registerDuplicate() throws {
        var registry = ParameterTypeRegistry()
        let colorType = ParameterType<String>(
            name: "color",
            regexps: ["red|green|blue"],
            type: String.self,
            converter: { $0 }
        )
        try registry.register(colorType)

        let duplicate = ParameterType<String>(
            name: "color",
            regexps: ["cyan|magenta|yellow"],
            type: String.self,
            converter: { $0 }
        )
        #expect(throws: ParameterTypeError.duplicateName("color")) {
            try registry.register(duplicate)
        }
    }

    @Test("register type-erased custom type")
    func registerAnyType() throws {
        var registry = ParameterTypeRegistry()
        let custom = AnyParameterType(
            name: "direction",
            regexps: ["north|south|east|west"],
            transformer: { $0 }
        )
        try registry.registerAny(custom)
        let looked = try #require(registry.lookup("direction"))
        #expect(looked.name == "direction")
    }

    @Test("lookup unknown type returns nil")
    func lookupUnknown() {
        let registry = ParameterTypeRegistry()
        #expect(registry.lookup("nonexistent") == nil)
    }

    @Test("registeredNames includes all built-in types")
    func registeredNamesIncludesBuiltIns() {
        let registry = ParameterTypeRegistry()
        let names = Set(registry.registeredNames)
        #expect(names.contains("int"))
        #expect(names.contains("float"))
        #expect(names.contains("string"))
        #expect(names.contains("word"))
        #expect(names.contains(""))
    }

    // MARK: - ParameterType.erased()

    @Test("typed parameter type erases to AnyParameterType")
    func erasedType() throws {
        let typed = ParameterType<Int>(
            name: "quantity",
            regexps: [#"\d+"#],
            type: Int.self,
            useForSnippets: false,
            preferForRegexpMatch: true,
            converter: { Int($0) ?? 0 }
        )
        let erased = typed.erased()
        #expect(erased.name == "quantity")
        #expect(erased.regexps == [#"\d+"#])
        #expect(erased.useForSnippets == false)
        #expect(erased.preferForRegexpMatch == true)
        // Transformer returns raw string
        let result = try erased.transformer("42")
        #expect(result == "42")
    }
}
