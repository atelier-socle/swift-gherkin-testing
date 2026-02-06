// Plugin.swift
// GherkinTestingMacros
//
// Copyright © 2026 Atelier Socle. MIT License.

import SwiftCompilerPlugin
import SwiftSyntaxMacros

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
        StepLibraryMacro.self,
    ]
}
