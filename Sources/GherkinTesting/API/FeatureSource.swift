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

/// The source of a Gherkin feature for parsing and execution.
///
/// A `FeatureSource` specifies where the Gherkin text comes from:
/// - ``inline(_:)`` for a string literal embedded directly in the source code
/// - ``file(_:)`` for a `.feature` file path resolved at runtime
///
/// ```swift
/// @Feature(source: .inline("""
///     Feature: Login
///       Scenario: Successful login
///         Given the user is on the login page
///         When they enter valid credentials
///         Then they should see the dashboard
///     """))
/// struct LoginFeature { ... }
///
/// @Feature(source: .file("Features/login.feature"))
/// struct LoginFeatureFromFile { ... }
/// ```
@frozen
public enum FeatureSource: Sendable, Equatable, Hashable {
    /// A Gherkin source embedded as a string literal.
    ///
    /// The macro can extract scenario names at compile time for per-scenario `@Test` methods.
    /// - Parameter source: The complete Gherkin text.
    case inline(String)

    /// A path to a `.feature` file resolved at runtime.
    ///
    /// The file is parsed at runtime; only a single `@Test` method is generated.
    /// - Parameter path: The file path relative to the test bundle or an absolute path.
    case file(String)
}
