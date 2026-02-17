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

/// A Background block providing common precondition steps for all scenarios
/// in a Feature or Rule.
///
/// Background steps are automatically prepended to every Scenario and
/// Scenario Outline within the same scope. A Feature may have at most one
/// Background, and each Rule may have its own independent Background.
///
/// ```gherkin
/// Background:
///   Given the system has the following users:
///     | username | role  |
///     | alice    | admin |
///     | bob      | user  |
///   And the database is clean
/// ```
public struct Background: Sendable, Equatable, Hashable {
    /// The location of the `Background` keyword in the source file.
    public let location: Location

    /// The keyword used to introduce this block.
    ///
    /// Typically `"Background"` in English, but may be a localized keyword
    /// when using internationalized Gherkin.
    public let keyword: String

    /// The name following the keyword, if any.
    ///
    /// Background blocks usually have no name, in which case this value
    /// is an empty string. A name is permitted by the Gherkin specification
    /// but is rarely used in practice.
    public let name: String

    /// An optional multiline description following the name line.
    ///
    /// Descriptions provide additional human-readable context for the
    /// Background block. This value is `nil` when no description is present.
    public let description: String?

    /// The ordered list of steps in this Background.
    ///
    /// These steps are prepended to every Scenario and Scenario Outline
    /// within the same Feature or Rule scope during pickle compilation.
    public let steps: [Step]

    /// Creates a new Background block.
    ///
    /// - Parameters:
    ///   - location: The source location of the `Background` keyword.
    ///   - keyword: The keyword text (e.g. `"Background"`).
    ///   - name: The name following the keyword, or an empty string if unnamed.
    ///   - description: An optional multiline description.
    ///   - steps: The ordered list of precondition steps.
    public init(
        location: Location,
        keyword: String,
        name: String,
        description: String?,
        steps: [Step]
    ) {
        self.location = location
        self.keyword = keyword
        self.name = name
        self.description = description
        self.steps = steps
    }
}
