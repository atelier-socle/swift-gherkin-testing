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

import SwiftCompilerPlugin
import SwiftSyntaxMacros

// Coverage: excluded — compile-time only (executed by the Swift compiler, not test runner)
/// Entry point for the GherkinTesting compiler plugin.
///
/// Registers all macros provided by the GherkinTesting framework:
/// - `@Feature` — Peer macro generating `@Suite`/`@Test` for a Gherkin feature
/// - `@Given`, `@When`, `@Then`, `@And`, `@But` — Peer macros generating step definitions
/// - `@Before`, `@After` — Peer macros generating lifecycle hooks
/// - `@StepLibrary` — Member + Extension macro for reusable step libraries
@main
struct GherkinTestingMacrosPlugin: CompilerPlugin {
    let providingMacros: [any Macro.Type] = [
        FeatureMacro.self,
        GivenMacro.self,
        WhenMacro.self,
        ThenMacro.self,
        AndMacro.self,
        ButMacro.self,
        BeforeMacro.self,
        AfterMacro.self,
        StepLibraryMacro.self
    ]
}
