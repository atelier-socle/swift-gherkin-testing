// SPDX-License-Identifier: Apache-2.0
//
// Copyright 2026 Atelier Socle SAS
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import Foundation

/// An error that occurs when working with parameter types.
public enum ParameterTypeError: Error, Sendable, Equatable, LocalizedError {
    /// A parameter type with the given name is already registered.
    ///
    /// - Parameter name: The duplicate parameter type name.
    case duplicateName(String)

    /// No parameter type is registered with the given name.
    ///
    /// - Parameter name: The unknown parameter type name.
    case unknownType(String)

    /// A captured string could not be converted by the parameter type's transformer.
    ///
    /// - Parameters:
    ///   - value: The captured string.
    ///   - typeName: The parameter type name.
    case transformFailed(value: String, typeName: String)

    /// A localized description of the parameter type error.
    public var errorDescription: String? {
        switch self {
        case .duplicateName(let name):
            return "Parameter type '\(name)' is already registered."
        case .unknownType(let name):
            return "Unknown parameter type '\(name)'. Register it before use."
        case .transformFailed(let value, let typeName):
            return "Cannot convert '\(value)' to parameter type '\(typeName)'."
        }
    }
}

/// A registry of Cucumber Expression parameter types.
///
/// Provides O(1) lookup by name via an internal dictionary. Ships with
/// the five built-in types (`{int}`, `{float}`, `{string}`, `{word}`, `{}`)
/// and supports registering custom types.
///
/// ```swift
/// var registry = ParameterTypeRegistry()
/// try registry.register(ParameterType<Color>(
///     name: "color",
///     regexps: ["red|green|blue"],
///     type: Color.self
/// ) { Color(rawValue: $0)! })
/// let intType = registry.lookup("int")
/// ```
public struct ParameterTypeRegistry: Sendable {
    /// The internal dictionary for O(1) lookup by name.
    private var types: [String: AnyParameterType]

    /// Creates a new registry pre-populated with the built-in Cucumber types.
    public init() {
        types = [:]
        registerBuiltInTypes()
    }

    /// Looks up a parameter type by name.
    ///
    /// - Parameter name: The parameter type name (e.g. `"int"`, `"float"`).
    /// - Returns: The parameter type, or `nil` if not registered.
    public func lookup(_ name: String) -> AnyParameterType? {
        types[name]
    }

    /// Returns all registered parameter type names.
    public var registeredNames: [String] {
        Array(types.keys)
    }

    /// Registers a custom typed parameter type.
    ///
    /// - Parameter parameterType: The typed parameter type to register.
    /// - Throws: ``ParameterTypeError/duplicateName(_:)`` if a type with
    ///   the same name is already registered.
    public mutating func register<T>(_ parameterType: ParameterType<T>) throws {
        guard types[parameterType.name] == nil else {
            throw ParameterTypeError.duplicateName(parameterType.name)
        }
        types[parameterType.name] = parameterType.erased()
    }

    /// Registers a type-erased parameter type.
    ///
    /// - Parameter parameterType: The type-erased parameter type to register.
    /// - Throws: ``ParameterTypeError/duplicateName(_:)`` if a type with
    ///   the same name is already registered.
    public mutating func registerAny(_ parameterType: AnyParameterType) throws {
        guard types[parameterType.name] == nil else {
            throw ParameterTypeError.duplicateName(parameterType.name)
        }
        types[parameterType.name] = parameterType
    }

    /// Strips surrounding quotes (double or single) from a captured string.
    ///
    /// - Parameter captured: The raw captured string.
    /// - Returns: The string with surrounding quotes removed.
    private static func stripQuotes(_ captured: String) -> String {
        if captured.count >= 2 {
            let first = captured.first
            let last = captured.last
            if (first == "\"" && last == "\"") || (first == "'" && last == "'") {
                return String(captured.dropFirst().dropLast())
            }
        }
        return captured
    }

    /// Registers the five built-in Cucumber Expression parameter types.
    private mutating func registerBuiltInTypes() {
        // {int} → -?\d+ → Int
        types["int"] = AnyParameterType(
            name: "int",
            regexps: [#"-?\d+"#],
            preferForRegexpMatch: true,
            transformer: { $0 },
            typedTransformer: { raw in
                guard let value = Int(raw) else {
                    throw ParameterTypeError.transformFailed(value: raw, typeName: "int")
                }
                return value
            }
        )

        // {float} → -?\d*\.\d+ → Double
        types["float"] = AnyParameterType(
            name: "float",
            regexps: [#"-?\d*\.\d+"#],
            preferForRegexpMatch: true,
            transformer: { $0 },
            typedTransformer: { raw in
                guard let value = Double(raw) else {
                    throw ParameterTypeError.transformFailed(value: raw, typeName: "float")
                }
                return value
            }
        )

        // {string} → "([^"]*)" or '([^']*)' → String (quotes stripped)
        types["string"] = AnyParameterType(
            name: "string",
            regexps: [#""[^"]*""#, #"'[^']*'"#],
            transformer: { Self.stripQuotes($0) },
            typedTransformer: { raw in Self.stripQuotes(raw) as String }
        )

        // {word} → [^\s]+ → String
        types["word"] = AnyParameterType(
            name: "word",
            regexps: [#"[^\s]+"#],
            transformer: { $0 },
            typedTransformer: { $0 as String }
        )

        // {} (anonymous) → .+ → String
        types[""] = AnyParameterType(
            name: "",
            regexps: [".+"],
            useForSnippets: false,
            transformer: { $0 },
            typedTransformer: { $0 as String }
        )
    }
}
