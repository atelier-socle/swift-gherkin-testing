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
