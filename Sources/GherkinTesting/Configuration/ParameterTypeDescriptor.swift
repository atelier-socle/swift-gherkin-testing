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
