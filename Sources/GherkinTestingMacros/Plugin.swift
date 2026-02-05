// Plugin.swift
// GherkinTestingMacros
//
// Copyright © 2026 Atelier Socle. MIT License.

import SwiftCompilerPlugin
import SwiftSyntaxMacros

/// Entry point for the GherkinTesting compiler plugin.
///
/// Registers all macros provided by the GherkinTesting framework.
/// Currently a stub — macro implementations will be added in Phase 4.
@main
struct GherkinTestingMacrosPlugin: CompilerPlugin {
    let providingMacros: [any Macro.Type] = []
}
