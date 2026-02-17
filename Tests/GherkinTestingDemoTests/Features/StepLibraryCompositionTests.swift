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

import GherkinTesting
import Testing

// MARK: - Step Library Composition Demo

/// A minimal step library used to prove `stepLibraries:` composition works end-to-end.
@StepLibrary
struct GreetingSteps {
    @Given("a greeting is prepared")
    func greetingPrepared() async throws {
        await Task.yield()
    }

    @Then("the greeting is delivered")
    func greetingDelivered() async throws {
        await Task.yield()
    }
}

/// Proves that `@Feature(stepLibraries:)` composes step definitions from a library.
///
/// The feature struct has NO local step definitions — all steps are provided by
/// `GreetingSteps` via the `stepLibraries:` parameter. The macro generates:
/// ```
/// static var __stepDefinitions: [StepDefinition<Self>] {
///     var defs: [StepDefinition<Self>] = []
///     defs += GreetingSteps.__stepDefinitions.map {
///         $0.retyped(for: Self.self, using: { GreetingSteps() })
///     }
///     return defs
/// }
/// ```
@Feature(
    source: .inline(
        """
        Feature: Library Composition
          Scenario: Steps from library
            Given a greeting is prepared
            Then the greeting is delivered
        """),
    stepLibraries: [GreetingSteps.self]
)
struct LibraryCompositionFeature {
}
