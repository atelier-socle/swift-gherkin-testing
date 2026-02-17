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

/// A Rule groups related scenarios under a single business rule within a Feature.
///
/// Rules provide an additional level of organization between Features and
/// Scenarios. Each Rule can have its own Background that applies only
/// to the scenarios within that Rule, independent of the Feature-level
/// Background.
///
/// ```gherkin
/// Feature: Account management
///
///   Rule: Users must verify their email
///     Background:
///       Given a user has registered with an unverified email
///
///     Scenario: User verifies email
///       When they click the verification link
///       Then their email should be verified
///
///     @wip
///     Scenario: Verification link expires
///       Given the link is older than 24 hours
///       When they click the verification link
///       Then they should see an expiration error
/// ```
public struct Rule: Sendable, Equatable, Hashable {
    /// The location of the `Rule` keyword in the source file.
    public let location: Location

    /// The tags applied to this Rule.
    ///
    /// Tags from the parent Feature are inherited during pickle compilation
    /// but are not included in this array, which contains only the tags
    /// declared directly on this Rule.
    public let tags: [Tag]

    /// The keyword used to introduce this block.
    ///
    /// Typically `"Rule"` in English, but may be a localized keyword
    /// when using internationalized Gherkin.
    public let keyword: String

    /// The name of the rule.
    ///
    /// This is the descriptive text following the keyword on the same line
    /// (e.g. `"Users must verify their email"`). This value is an empty
    /// string when no name is provided.
    public let name: String

    /// An optional multiline description following the name line.
    ///
    /// Descriptions provide additional human-readable context for the
    /// rule. This value is `nil` when no description is present.
    public let description: String?

    /// The ordered children of this Rule, preserving source order.
    ///
    /// Children include Backgrounds and Scenarios in the order they
    /// appear in the source file.
    public let children: [RuleChild]

    /// Creates a new Rule block.
    ///
    /// - Parameters:
    ///   - location: The source location of the `Rule` keyword.
    ///   - tags: The tags declared directly on this Rule.
    ///   - keyword: The keyword text (e.g. `"Rule"`).
    ///   - name: The rule name, or an empty string if unnamed.
    ///   - description: An optional multiline description.
    ///   - children: The ordered children (Backgrounds, Scenarios).
    public init(
        location: Location,
        tags: [Tag],
        keyword: String,
        name: String,
        description: String?,
        children: [RuleChild]
    ) {
        self.location = location
        self.tags = tags
        self.keyword = keyword
        self.name = name
        self.description = description
        self.children = children
    }

    // MARK: - Convenience Accessors

    /// The Background block scoped to this Rule, if any.
    ///
    /// Returns the first `.background` child. Per the Gherkin specification,
    /// a Rule may have at most one Background.
    public var background: Background? {
        children.lazy.compactMap {
            if case .background(let bg) = $0 { return bg }
            return nil
        }.first
    }

    /// The Scenarios contained within this Rule.
    ///
    /// Returns all `.scenario` children in source order.
    public var scenarios: [Scenario] {
        children.compactMap {
            if case .scenario(let s) = $0 { return s }
            return nil
        }
    }
}
