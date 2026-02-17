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

/// A type-erased parameter type descriptor used by ``ParameterTypeRegistry``.
///
/// Stores the name, regex patterns, a string transformer (for ``CucumberMatch/rawArguments``),
/// and a typed transformer (for ``CucumberMatch/typedArguments``).
///
/// ```swift
/// let intType = AnyParameterType(
///     name: "int",
///     regexps: [#"-?\d+"#],
///     transformer: { $0 },
///     typedTransformer: { guard let v = Int($0) else { throw ... }; return v }
/// )
/// ```
public struct AnyParameterType: Sendable {
    /// The parameter type name used in expressions (e.g. `"int"`, `"float"`, `"string"`).
    public let name: String

    /// The regex patterns this parameter type can match.
    ///
    /// Multiple patterns are supported for types like `{string}` which matches
    /// both `"double quoted"` and `'single quoted'` strings.
    public let regexps: [String]

    /// Whether this type should be used in generated step definition snippets.
    public let useForSnippets: Bool

    /// Whether this type is preferred when multiple types match the same text.
    public let preferForRegexpMatch: Bool

    /// Transforms a raw captured string into a cleaned string value.
    ///
    /// Used to populate ``CucumberMatch/rawArguments``. For example, `{string}`
    /// strips surrounding quotes, while `{int}` returns the raw digit string.
    ///
    /// - Parameter captured: The raw captured string from regex matching.
    /// - Returns: The transformed string value.
    /// - Throws: If the transformation fails.
    public let transformer: @Sendable (String) throws -> String

    /// Converts a raw captured string into a typed value.
    ///
    /// Used to populate ``CucumberMatch/typedArguments``. For example,
    /// `{int}` converts `"-42"` to `Int(-42)`, `{float}` converts `"3.14"` to `Double(3.14)`.
    ///
    /// - Parameter captured: The raw captured string from regex matching.
    /// - Returns: The typed value (e.g. `Int`, `Double`, `String`, or a custom type).
    /// - Throws: ``ParameterTypeError/transformFailed(value:typeName:)`` if conversion fails.
    public let typedTransformer: @Sendable (String) throws -> any Sendable

    /// Creates a new type-erased parameter type.
    ///
    /// - Parameters:
    ///   - name: The parameter type name.
    ///   - regexps: The regex patterns to match.
    ///   - useForSnippets: Whether to use in snippets. Defaults to `true`.
    ///   - preferForRegexpMatch: Whether preferred for matching. Defaults to `false`.
    ///   - transformer: The string transformer closure.
    ///   - typedTransformer: The typed transformer closure. Defaults to the string transformer.
    public init(
        name: String,
        regexps: [String],
        useForSnippets: Bool = true,
        preferForRegexpMatch: Bool = false,
        transformer: @escaping @Sendable (String) throws -> String,
        typedTransformer: (@Sendable (String) throws -> any Sendable)? = nil
    ) {
        self.name = name
        self.regexps = regexps
        self.useForSnippets = useForSnippets
        self.preferForRegexpMatch = preferForRegexpMatch
        self.transformer = transformer
        self.typedTransformer = typedTransformer ?? transformer
    }
}

/// A typed parameter type that converts captured strings to a specific Swift type.
///
/// Use this to register custom parameter types with ``ParameterTypeRegistry``.
///
/// ```swift
/// let colorType = ParameterType<Color>(
///     name: "color",
///     regexps: ["red|green|blue"],
///     type: Color.self
/// ) { Color(rawValue: $0) ?? .red }
/// ```
public struct ParameterType<T: Sendable>: Sendable {
    /// The parameter type name used in expressions (e.g. `"color"`).
    public let name: String

    /// The regex patterns this parameter type can match.
    public let regexps: [String]

    /// The Swift type this parameter converts to.
    public let type: T.Type

    /// Whether this type should be used in generated step definition snippets.
    public let useForSnippets: Bool

    /// Whether this type is preferred when multiple types match the same text.
    public let preferForRegexpMatch: Bool

    /// Converts a raw captured string to the typed value.
    ///
    /// - Parameter captured: The raw captured string.
    /// - Returns: The converted typed value.
    /// - Throws: If conversion fails.
    public let converter: @Sendable (String) throws -> T

    /// Creates a new typed parameter type.
    ///
    /// - Parameters:
    ///   - name: The parameter type name.
    ///   - regexps: The regex patterns to match.
    ///   - type: The Swift type to convert to.
    ///   - useForSnippets: Whether to use in snippets. Defaults to `true`.
    ///   - preferForRegexpMatch: Whether preferred for matching. Defaults to `false`.
    ///   - converter: The conversion closure.
    public init(
        name: String,
        regexps: [String],
        type: T.Type,
        useForSnippets: Bool = true,
        preferForRegexpMatch: Bool = false,
        converter: @escaping @Sendable (String) throws -> T
    ) {
        self.name = name
        self.regexps = regexps
        self.type = type
        self.useForSnippets = useForSnippets
        self.preferForRegexpMatch = preferForRegexpMatch
        self.converter = converter
    }

    /// Converts this typed parameter type to an ``AnyParameterType``.
    ///
    /// The string transformer returns the raw captured string.
    /// The typed transformer invokes the original ``converter`` to produce the typed value.
    ///
    /// - Returns: A type-erased parameter type.
    public func erased() -> AnyParameterType {
        let typedConverter = converter
        return AnyParameterType(
            name: name,
            regexps: regexps,
            useForSnippets: useForSnippets,
            preferForRegexpMatch: preferForRegexpMatch,
            transformer: { $0 },
            typedTransformer: { raw in try typedConverter(raw) }
        )
    }
}
