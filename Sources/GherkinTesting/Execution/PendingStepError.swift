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

/// An error thrown by a step handler to indicate that the step implementation is pending.
///
/// When a step handler throws `PendingStepError`, the step is marked as
/// ``StepStatus/pending`` rather than ``StepStatus/failed(_:)``. Subsequent steps
/// in the same scenario are marked as ``StepStatus/skipped``.
///
/// ```swift
/// @Given("the user activates two-factor auth")
/// func activateTwoFactor() async throws {
///     throw PendingStepError("Not yet implemented")
/// }
/// ```
public struct PendingStepError: Error, Sendable, Equatable {
    /// A description of why the step is pending.
    public let message: String

    /// Creates a new pending step error.
    ///
    /// - Parameter message: A description of why the step is pending.
    ///   Defaults to `"Step implementation pending"`.
    public init(_ message: String = "Step implementation pending") {
        self.message = message
    }
}

extension PendingStepError: LocalizedError {
    /// A localized description of the pending step error.
    public var errorDescription: String? {
        message
    }
}
