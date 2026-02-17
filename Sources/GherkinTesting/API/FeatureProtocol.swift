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

/// A protocol that user-defined feature types conform to for BDD test execution.
///
/// Types conforming to `GherkinFeature` represent a Gherkin Feature file and
/// contain the step implementations as methods. The `@Feature` macro generates
/// conformance automatically.
///
/// Override ``gherkinConfiguration`` to customize execution (reporters, dry-run,
/// tag filtering):
///
/// ```swift
/// @Feature(source: .inline("..."))
/// struct LoginFeature {
///     static var gherkinConfiguration: GherkinConfiguration {
///         GherkinConfiguration(reporters: [CucumberJSONReporter()])
///     }
///
///     @Given("the user is logged in")
///     func loggedIn() { }
/// }
/// ```
public protocol GherkinFeature: Sendable {
    /// The configuration used when executing this feature's scenarios.
    ///
    /// Override this property to customize reporters, dry-run mode, or tag filtering.
    /// The default implementation returns ``GherkinConfiguration/default``.
    static var gherkinConfiguration: GherkinConfiguration { get }
}

extension GherkinFeature {
    /// Default configuration that runs all scenarios with no filtering or reporters.
    public static var gherkinConfiguration: GherkinConfiguration { .default }
}
