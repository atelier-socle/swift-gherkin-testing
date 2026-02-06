// HookMacroTests.swift
// GherkinTestingMacroTests
//
// Copyright © 2026 Atelier Socle. MIT License.

import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import Testing

@testable import GherkinTestingMacros

private var testMacros: [String: any Macro.Type] {
    [
        "Before": BeforeMacro.self,
        "After": AfterMacro.self
    ]
}

@Suite("Hook Macro Expansion Tests")
struct HookMacroTests {

    @Test("@Before with scenario scope generates hook property")
    func beforeScenario() {
        assertMacroExpansion(
            """
            @Before(.scenario)
            static func setUp() async throws {
            }
            """,
            expandedSource: """
                static func setUp() async throws {
                }

                static let __hook_setUp = Hook(
                    scope: .scenario,
                    tagFilter: nil,
                    handler: { try await setUp() }
                )
                """,
            macros: testMacros
        )
    }

    @Test("@After with feature scope generates hook property")
    func afterFeature() {
        assertMacroExpansion(
            """
            @After(.feature)
            static func tearDown() {
            }
            """,
            expandedSource: """
                static func tearDown() {
                }

                static let __hook_tearDown = Hook(
                    scope: .feature,
                    tagFilter: nil,
                    handler: { tearDown() }
                )
                """,
            macros: testMacros
        )
    }

    @Test("@Before with tag filter generates hook with filter")
    func beforeWithTags() {
        assertMacroExpansion(
            """
            @Before(.scenario, tags: "@smoke")
            static func smokeSetup() {
            }
            """,
            expandedSource: """
                static func smokeSetup() {
                }

                static let __hook_smokeSetup = Hook(
                    scope: .scenario,
                    tagFilter: try? TagFilter("@smoke"),
                    handler: { smokeSetup() }
                )
                """,
            macros: testMacros
        )
    }

    @Test("@Before on non-static function emits diagnostic")
    func beforeNonStaticDiagnoses() {
        assertMacroExpansion(
            """
            @Before(.scenario)
            func setUp() {
            }
            """,
            expandedSource: """
                func setUp() {
                }
                """,
            diagnostics: [
                DiagnosticSpec(
                    message: "@Before/@After hooks must be applied to static functions",
                    line: 2,
                    column: 1
                )
            ],
            macros: testMacros
        )
    }

    @Test("@After on a property emits diagnostic")
    func afterOnPropertyDiagnoses() {
        assertMacroExpansion(
            """
            @After(.scenario)
            var foo = 42
            """,
            expandedSource: """
                var foo = 42
                """,
            diagnostics: [
                DiagnosticSpec(
                    message: "@Before/@After can only be applied to functions",
                    line: 2,
                    column: 1
                )
            ],
            macros: testMacros
        )
    }
}
