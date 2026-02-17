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

/// A tag annotation on a Feature, Rule, Scenario, or Examples block.
///
/// Tags begin with `@` in Gherkin source and are used for filtering
/// and organizing test scenarios.
///
/// ```gherkin
/// @smoke @login
/// Scenario: User logs in
/// ```
public struct Tag: Sendable, Equatable, Hashable {
    /// The location of this tag in the source file.
    public let location: Location

    /// The tag name including the `@` prefix (e.g. `"@smoke"`).
    public let name: String

    /// Creates a new tag.
    ///
    /// - Parameters:
    ///   - location: The source location of the tag.
    ///   - name: The full tag name including `@` prefix.
    public init(location: Location, name: String) {
        self.location = location
        self.name = name
    }
}
