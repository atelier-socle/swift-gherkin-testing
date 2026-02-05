// StepKeywordType.swift
// GherkinTesting
//
// Copyright © 2026 Atelier Socle. MIT License.

/// The semantic type of a step keyword.
///
/// In Gherkin, each step begins with a keyword (`Given`, `When`, `Then`,
/// `And`, `But`, or `*`). The keyword type indicates the semantic role
/// of the step in the scenario.
///
/// Conjunction keywords (`And`, `But`, `*`) inherit their semantic type
/// from the preceding step during parsing. For example, an `And` step
/// following a `Given` step has a resolved type of ``context``.
///
/// ```gherkin
/// Given the user is logged in       # context
/// And they are on the home page      # conjunction → resolved to context
/// When they click the logout button  # action
/// Then they should see the login page # outcome
/// ```
@frozen
public enum StepKeywordType: String, Sendable, Equatable, Hashable {
    /// A context step, typically introduced by `Given`.
    ///
    /// Context steps establish the initial state of the system before
    /// the action under test occurs.
    case context

    /// An action step, typically introduced by `When`.
    ///
    /// Action steps describe the event or interaction being tested.
    case action

    /// An outcome step, typically introduced by `Then`.
    ///
    /// Outcome steps assert the expected result after the action.
    case outcome

    /// A conjunction step introduced by `And`, `But`, or `*`.
    ///
    /// Conjunction steps inherit their semantic type from the preceding
    /// step. This case represents the unresolved state before type
    /// resolution is applied during parsing.
    case conjunction

    /// An unresolved step type.
    ///
    /// Used when the semantic type cannot be determined, for example
    /// when a conjunction step appears at the beginning of a scenario
    /// with no preceding step to inherit from.
    case unknown
}
