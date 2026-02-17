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

/// A multi-line string argument attached to a step.
///
/// Doc strings are delimited by triple quotes or triple backticks.
/// They allow passing large blocks of text, JSON, XML, or other
/// content as a step argument.
public struct DocString: Sendable, Equatable, Hashable {
    /// The location of the opening delimiter in the source file.
    public let location: Location

    /// An optional media type hint following the opening delimiter.
    ///
    /// For example, `"json"` when the doc string opens with a media type.
    /// This value is `nil` when no media type is specified.
    public let mediaType: String?

    /// The content between the opening and closing delimiters.
    ///
    /// Leading indentation matching the delimiter's indentation is stripped.
    /// The content does not include the delimiters themselves.
    public let content: String

    /// The delimiter used to open and close this doc string.
    ///
    /// Either triple quotes or triple backticks.
    public let delimiter: String

    /// Creates a new doc string.
    ///
    /// - Parameters:
    ///   - location: The source location of the opening delimiter.
    ///   - mediaType: An optional media type hint (e.g. `"json"`, `"xml"`).
    ///   - content: The text content between the delimiters.
    ///   - delimiter: The delimiter used (triple quotes or triple backticks).
    public init(location: Location, mediaType: String?, content: String, delimiter: String) {
        self.location = location
        self.mediaType = mediaType
        self.content = content
        self.delimiter = delimiter
    }
}
