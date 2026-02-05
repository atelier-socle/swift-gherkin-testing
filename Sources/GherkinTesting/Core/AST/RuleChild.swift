// RuleChild.swift
// GherkinTesting
//
// Copyright © 2026 Atelier Socle. MIT License.

/// A child element of a ``Rule``, preserving source order.
///
/// Rules may contain a Background and Scenarios in any order.
/// This enum models the ordered `children` array from the Gherkin AST
/// specification, ensuring interleaving order is preserved.
///
/// ```gherkin
/// Rule: Business rule
///   Background:
///     Given rule setup
///
///   Scenario: First
///     Given step
///
///   Scenario: Second
///     Given step
/// ```
@frozen
public enum RuleChild: Sendable, Equatable, Hashable {
    /// A Background block scoped to this Rule.
    case background(Background)

    /// A Scenario or Scenario Outline within this Rule.
    case scenario(Scenario)
}
