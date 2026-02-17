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

/// The root node of a Gherkin AST representing an entire `.feature` file.
///
/// A `GherkinDocument` is the top-level container produced by the parser.
/// It holds an optional ``Feature`` (since a file could be empty or contain
/// only comments) and all ``Comment`` nodes found anywhere in the source.
///
/// ```swift
/// let parser = GherkinParser()
/// let document = try parser.parse(source: featureText)
///
/// if let feature = document.feature {
///     print("Feature: \(feature.name)")
/// }
///
/// for comment in document.comments {
///     print("Comment at line \(comment.location.line): \(comment.text)")
/// }
/// ```
public struct GherkinDocument: Sendable, Equatable, Hashable {
    /// The Feature defined in this document, if any.
    ///
    /// This value is `nil` when the source file is empty, contains only
    /// comments, or does not include a `Feature` keyword. A valid `.feature`
    /// file typically contains exactly one Feature.
    public let feature: Feature?

    /// All comments found in the source file.
    ///
    /// Comments are preserved in source order and include the `#` prefix.
    /// They carry no semantic meaning but are retained in the AST for
    /// round-trip fidelity and tooling support.
    public let comments: [Comment]

    /// Creates a new Gherkin document.
    ///
    /// - Parameters:
    ///   - feature: The Feature defined in the document, or `nil` if absent.
    ///   - comments: All comments found in the source file.
    public init(feature: Feature?, comments: [Comment]) {
        self.feature = feature
        self.comments = comments
    }
}
