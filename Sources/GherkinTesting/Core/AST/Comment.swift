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

/// A comment line in a Gherkin source file.
///
/// Comments start with `#` and extend to the end of the line.
/// They are preserved in the AST but have no semantic meaning.
///
/// ```gherkin
/// # This is a comment
/// Feature: Login
/// ```
public struct Comment: Sendable, Equatable, Hashable {
    /// The location of this comment in the source file.
    public let location: Location

    /// The full text of the comment line, including the `#` prefix.
    public let text: String

    /// Creates a new comment.
    ///
    /// - Parameters:
    ///   - location: The source location where the comment begins.
    ///   - text: The full comment text including the `#` prefix.
    public init(location: Location, text: String) {
        self.location = location
        self.text = text
    }
}
