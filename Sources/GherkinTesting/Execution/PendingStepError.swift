// PendingStepError.swift
// GherkinTesting
//
// Copyright © 2026 Atelier Socle. MIT License.

import Foundation

/// An error thrown by a step handler to indicate that the step implementation is pending.
///
/// When a step handler throws `PendingStepError`, the step is marked as
/// ``StepStatus/pending`` rather than ``StepStatus/failed``. Subsequent steps
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
