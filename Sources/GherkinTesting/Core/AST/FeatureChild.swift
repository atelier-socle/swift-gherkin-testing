// FeatureChild.swift
// GherkinTesting
//
// Copyright © 2026 Atelier Socle. MIT License.

/// A child element of a ``Feature``, preserving source order.
///
/// Features may contain Backgrounds, Scenarios, and Rules in any order.
/// This enum models the ordered `children` array from the Gherkin AST
/// specification, ensuring interleaving order is preserved.
///
/// ```gherkin
/// Feature: Example
///   Background:
///     Given setup
///
///   Scenario: First
///     Given step
///
///   Rule: Business rule
///     Scenario: Inside rule
///       Given step
/// ```
@frozen
public enum FeatureChild: Sendable, Equatable, Hashable {
    /// A Background block at the Feature level.
    case background(Background)

    /// A Scenario or Scenario Outline at the Feature level.
    case scenario(Scenario)

    /// A Rule block grouping related scenarios.
    case rule(Rule)
}
