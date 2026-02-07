// ParameterTypeDescriptor.swift
// GherkinTesting
//
// Copyright © 2026 Atelier Socle. MIT License.

/// A declarative description of a custom Cucumber Expression parameter type.
///
/// Use this to register custom parameter types in ``GherkinConfiguration``
/// without directly interacting with the ``ParameterTypeRegistry`` API.
/// Custom types are matched as strings — the matched text is passed as a
/// `String` argument to step handlers.
///
/// ```swift
/// let config = GherkinConfiguration(
///     parameterTypes: [
///         .type("color", matching: "red|green|blue"),
///         .type("amount", matching: #"\d+\.\d{2}"#)
///     ]
/// )
/// ```
public struct ParameterTypeDescriptor: Sendable, Equatable {
    /// The name used in Cucumber expressions (e.g. `"color"` for `{color}`).
    public let name: String

    /// The regex patterns this type matches.
    public let patterns: [String]

    /// Creates a descriptor with a single regex pattern.
    ///
    /// - Parameters:
    ///   - name: The parameter type name used in expressions (e.g. `"color"` for `{color}`).
    ///   - pattern: The regex pattern to match (e.g. `"red|green|blue"`).
    /// - Returns: A new descriptor.
    public static func type(_ name: String, matching pattern: String) -> ParameterTypeDescriptor {
        ParameterTypeDescriptor(name: name, patterns: [pattern])
    }

    /// Creates a descriptor with multiple regex patterns.
    ///
    /// - Parameters:
    ///   - name: The parameter type name used in expressions (e.g. `"color"` for `{color}`).
    ///   - patterns: The regex patterns to match.
    /// - Returns: A new descriptor.
    public static func type(_ name: String, matchingAny patterns: [String]) -> ParameterTypeDescriptor {
        ParameterTypeDescriptor(name: name, patterns: patterns)
    }
}
