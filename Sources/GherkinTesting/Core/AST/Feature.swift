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

/// The top-level Feature node in a Gherkin AST.
///
/// A Feature groups related Scenarios and Rules under a common domain concept.
/// It may have tags, a description, and an ordered list of children that
/// preserves the original source order of Backgrounds, Scenarios, and Rules.
///
/// ```gherkin
/// # language: en
/// @authentication
/// Feature: User login
///   As a registered user
///   I want to log in to my account
///   So that I can access protected resources
///
///   Background:
///     Given the application is running
///
///   Scenario: Successful login
///     Given valid credentials
///     When the user logs in
///     Then the dashboard is displayed
///
///   Rule: Failed login attempts
///     Scenario: Invalid password
///       Given valid username
///       When the user enters a wrong password
///       Then an error message is shown
/// ```
public struct Feature: Sendable, Equatable, Hashable {
    /// The location of the `Feature` keyword in the source file.
    public let location: Location

    /// The tags applied to this Feature.
    ///
    /// Feature-level tags are inherited by all Scenarios, Scenario Outlines,
    /// and Rules within this Feature during pickle compilation.
    public let tags: [Tag]

    /// The language code for this Feature.
    ///
    /// Determined by the `# language:` header at the top of the file, or
    /// defaults to `"en"` when no language header is present. This value
    /// controls which localized keywords are recognized by the parser.
    public let language: String

    /// The keyword used to introduce this Feature.
    ///
    /// Typically `"Feature"` in English, but may be a localized keyword
    /// (e.g. `"Fonctionnalité"` in French) when using internationalized
    /// Gherkin.
    public let keyword: String

    /// The name of the Feature.
    ///
    /// This is the descriptive text following the keyword on the same line
    /// (e.g. `"User login"`). This value is an empty string when no name
    /// is provided.
    public let name: String

    /// An optional multiline description following the name line.
    ///
    /// Descriptions typically follow the "As a / I want / So that" format
    /// but can contain any free-form text. This value is `nil` when no
    /// description is present.
    public let description: String?

    /// The ordered children of this Feature, preserving source order.
    ///
    /// Children include Backgrounds, Scenarios, Scenario Outlines, and Rules,
    /// in the order they appear in the source file.
    public let children: [FeatureChild]

    /// Creates a new Feature node.
    ///
    /// - Parameters:
    ///   - location: The source location of the `Feature` keyword.
    ///   - tags: The tags declared on this Feature.
    ///   - language: The language code (e.g. `"en"`, `"fr"`).
    ///   - keyword: The keyword text (e.g. `"Feature"`).
    ///   - name: The feature name, or an empty string if unnamed.
    ///   - description: An optional multiline description.
    ///   - children: The ordered children (Backgrounds, Scenarios, Rules).
    public init(
        location: Location,
        tags: [Tag],
        language: String,
        keyword: String,
        name: String,
        description: String?,
        children: [FeatureChild]
    ) {
        self.location = location
        self.tags = tags
        self.language = language
        self.keyword = keyword
        self.name = name
        self.description = description
        self.children = children
    }

    // MARK: - Convenience Accessors

    /// The Background block at the Feature level, if any.
    ///
    /// Returns the first `.background` child. Per the Gherkin specification,
    /// a Feature may have at most one Background.
    public var background: Background? {
        children.lazy.compactMap {
            if case .background(let bg) = $0 { return bg }
            return nil
        }.first
    }

    /// The Scenarios that are direct children of this Feature.
    ///
    /// Returns all `.scenario` children in source order, excluding
    /// scenarios nested inside Rules.
    public var scenarios: [Scenario] {
        children.compactMap {
            if case .scenario(let s) = $0 { return s }
            return nil
        }
    }

    /// The Rules contained within this Feature.
    ///
    /// Returns all `.rule` children in source order.
    public var rules: [Rule] {
        children.compactMap {
            if case .rule(let r) = $0 { return r }
            return nil
        }
    }
}
