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

/// A position within a Gherkin source file.
///
/// Locations are used to track the origin of AST nodes for diagnostics
/// and error reporting. Lines are 1-based; columns are 1-based when known
/// or `0` when unknown.
///
/// ```swift
/// let location = Location(line: 3, column: 5)
/// ```
public struct Location: Sendable, Equatable, Hashable {
    /// The 1-based line number in the source file.
    public let line: Int

    /// The 1-based column number in the source file, or `0` if unknown.
    public let column: Int

    /// Creates a new location.
    ///
    /// - Parameters:
    ///   - line: The 1-based line number.
    ///   - column: The 1-based column number. Defaults to `0` (unknown).
    public init(line: Int, column: Int = 0) {
        self.line = line
        self.column = column
    }
}
