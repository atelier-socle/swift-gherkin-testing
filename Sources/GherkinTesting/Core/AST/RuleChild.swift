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
