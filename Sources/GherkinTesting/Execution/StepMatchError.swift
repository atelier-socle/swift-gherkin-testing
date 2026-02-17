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

import Foundation

/// An error that occurs when matching a pickle step against step definitions.
///
/// Step match errors indicate that a step's text could not be uniquely resolved
/// to a single step definition. This can happen when no definitions match
/// (undefined), multiple definitions match (ambiguous), or a captured argument
/// cannot be converted to the expected type.
///
/// ```swift
/// do {
///     let match = try executor.match(step)
/// } catch let error as StepMatchError {
///     print(error.errorDescription ?? "Unknown match error")
/// }
/// ```
public enum StepMatchError: Error, Sendable, Equatable {
    /// No step definition was found that matches the step text.
    ///
    /// - Parameter stepText: The unmatched step text.
    case undefined(stepText: String)

    /// Multiple step definitions match the step text.
    ///
    /// - Parameters:
    ///   - stepText: The ambiguous step text.
    ///   - matchDescriptions: Pattern descriptions of all matching definitions.
    case ambiguous(stepText: String, matchDescriptions: [String])

    /// A captured argument could not be converted to the expected type.
    ///
    /// - Parameters:
    ///   - stepText: The step text where the mismatch occurred.
    ///   - expected: The expected type name.
    ///   - actual: The actual value that could not be converted.
    case typeMismatch(stepText: String, expected: String, actual: String)
}

extension StepMatchError: LocalizedError {
    /// A localized description of the step match error.
    public var errorDescription: String? {
        switch self {
        case .undefined(let stepText):
            return "Undefined step: \"\(stepText)\". No matching step definition was found."
        case .ambiguous(let stepText, let matchDescriptions):
            let matches = matchDescriptions.map { "  - \($0)" }.joined(separator: "\n")
            return "Ambiguous step: \"\(stepText)\". Multiple definitions match:\n\(matches)"
        case .typeMismatch(let stepText, let expected, let actual):
            return "Type mismatch in step: \"\(stepText)\". Expected \(expected), got \"\(actual)\"."
        }
    }
}
