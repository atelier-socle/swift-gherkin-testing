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

/// A tag on a compiled ``Pickle``.
///
/// Pickle tags are the result of tag inheritance during compilation.
/// They combine tags from the Feature, Rule, Scenario, and Examples
/// levels into a flat list for filtering.
///
/// ```swift
/// for tag in pickle.tags {
///     print(tag.name) // "@smoke"
/// }
/// ```
public struct PickleTag: Sendable, Equatable, Hashable {
    /// The tag name including the `@` prefix (e.g. `"@smoke"`).
    public let name: String

    /// The AST node ID of the original ``Tag`` this was derived from.
    ///
    /// Used for traceability back to the source AST.
    public let astNodeId: String

    /// Creates a new pickle tag.
    ///
    /// - Parameters:
    ///   - name: The tag name including `@` prefix.
    ///   - astNodeId: The ID of the source AST tag node.
    public init(name: String, astNodeId: String) {
        self.name = name
        self.astNodeId = astNodeId
    }
}
