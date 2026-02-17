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

import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import Testing

@testable import GherkinTestingMacros

private var testMacros: [String: any Macro.Type] {
    [
        "StepLibrary": StepLibraryMacro.self,
        "Given": GivenMacro.self,
        "When": WhenMacro.self,
        "Then": ThenMacro.self
    ]
}

@Suite("StepLibrary Macro Expansion Tests")
struct StepLibraryMacroTests {

    @Test("@StepLibrary generates __stepDefinitions and StepLibrary conformance")
    func stepLibraryBasic() {
        assertMacroExpansion(
            """
            @StepLibrary
            struct SharedSteps {
                @Given("logged in")
                func loggedIn() {
                }
                @When("click logout")
                func clickLogout() {
                }
            }
            """,
            expandedSource: """
                struct SharedSteps {
                    @Given("logged in")
                    func loggedIn() {
                    }
                    @When("click logout")
                    func clickLogout() {
                    }

                    static var __stepDefinitions: [StepDefinition<Self>] {
                        [__stepDef_loggedIn, __stepDef_clickLogout]
                    }
                }

                extension SharedSteps: StepLibrary {
                }
                """,
            macros: testMacros
        )
    }

    @Test("@StepLibrary with no step functions generates empty array")
    func stepLibraryEmpty() {
        assertMacroExpansion(
            """
            @StepLibrary
            struct EmptySteps {
            }
            """,
            expandedSource: """
                struct EmptySteps {

                    static var __stepDefinitions: [StepDefinition<Self>] {
                        []
                    }
                }

                extension EmptySteps: StepLibrary {
                }
                """,
            macros: testMacros
        )
    }

    @Test("@StepLibrary on class emits diagnostic")
    func stepLibraryOnClassDiagnoses() {
        assertMacroExpansion(
            """
            @StepLibrary
            class BadLibrary {
            }
            """,
            expandedSource: """
                class BadLibrary {
                }
                """,
            diagnostics: [
                DiagnosticSpec(
                    message: "@StepLibrary can only be applied to a struct",
                    line: 1,
                    column: 1
                )
            ],
            macros: testMacros
        )
    }
}
