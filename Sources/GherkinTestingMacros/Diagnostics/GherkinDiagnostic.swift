// GherkinDiagnostic.swift
// GherkinTestingMacros
//
// Copyright © 2026 Atelier Socle. MIT License.

import SwiftDiagnostics
import SwiftSyntax

/// Diagnostic messages emitted by GherkinTesting macros during compilation.
///
/// Each diagnostic provides a clear, actionable message and a unique identifier
/// for Xcode to display in the Issue Navigator.
enum GherkinDiagnostic: String, DiagnosticMessage {
    // MARK: - @Feature diagnostics

    /// The `source:` argument is missing from `@Feature`.
    case featureMissingSource

    /// The `source:` argument must be `.inline(...)` or `.file(...)`.
    case featureInvalidSource

    /// `@Feature` can only be applied to a `struct`.
    case featureRequiresStruct

    // MARK: - Step macro diagnostics

    /// A step macro expression argument must be a string literal.
    case stepExpressionNotStringLiteral

    /// A step macro can only be applied to a function declaration.
    case stepRequiresFunction

    /// The step expression string is empty.
    case stepExpressionEmpty

    /// The function parameter count does not match the number of capture groups.
    case stepParameterCountMismatch

    // MARK: - Hook macro diagnostics

    /// `@Before`/`@After` can only be applied to a `static` function.
    case hookRequiresStaticFunction

    /// `@Before`/`@After` can only be applied to a function declaration.
    case hookRequiresFunction

    /// The scope argument must be `.feature`, `.scenario`, or `.step`.
    case hookInvalidScope

    // MARK: - @StepLibrary diagnostics

    /// `@StepLibrary` can only be applied to a `struct`.
    case stepLibraryRequiresStruct

    // MARK: - DiagnosticMessage conformance

    var message: String {
        switch self {
        case .featureMissingSource:
            return "@Feature requires a 'source:' argument, e.g. @Feature(source: .inline(\"...\"))"
        case .featureInvalidSource:
            return "@Feature 'source:' must be .inline(\"...\") or .file(\"...\")"
        case .featureRequiresStruct:
            return "@Feature can only be applied to a struct"
        case .stepExpressionNotStringLiteral:
            return "Step expression must be a string literal"
        case .stepExpressionEmpty:
            return "Step expression must not be empty"
        case .stepRequiresFunction:
            return "Step macros (@Given, @When, @Then, @And, @But) can only be applied to functions"
        case .stepParameterCountMismatch:
            return "Number of function parameters must match the number of capture groups in the expression"
        case .hookRequiresStaticFunction:
            return "@Before/@After hooks must be applied to static functions"
        case .hookRequiresFunction:
            return "@Before/@After can only be applied to functions"
        case .hookInvalidScope:
            return "Hook scope must be .feature, .scenario, or .step"
        case .stepLibraryRequiresStruct:
            return "@StepLibrary can only be applied to a struct"
        }
    }

    var diagnosticID: MessageID {
        MessageID(domain: "GherkinTestingMacros", id: rawValue)
    }

    var severity: DiagnosticSeverity { .error }
}
