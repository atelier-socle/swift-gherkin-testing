// StepMacros.swift
// GherkinTestingMacros
//
// Copyright © 2026 Atelier Socle. MIT License.

import SwiftDiagnostics
import SwiftSyntax
import SwiftSyntaxMacros

/// Base implementation shared by all step macros (@Given, @When, @Then, @And, @But).
///
/// Each step macro is a `PeerMacro` that generates a `static let __stepDef_<funcName>`
/// declaration adjacent to the annotated function. The generated property holds a
/// `StepDefinition<Self>` with the appropriate keyword type and pattern.
enum StepMacroBase {

    /// Expands a step macro into a `StepDefinition` static property.
    ///
    /// - Parameters:
    ///   - node: The attribute syntax node for the macro invocation.
    ///   - declaration: The declaration the macro is attached to.
    ///   - context: The macro expansion context for emitting diagnostics.
    ///   - kind: The step keyword kind.
    /// - Returns: An array of peer declarations (the static step definition property).
    static func expansion(
        of node: AttributeSyntax,
        providingPeersOf declaration: some DeclSyntaxProtocol,
        in context: some MacroExpansionContext,
        kind: StepRegistryCodeGen.StepKind
    ) throws -> [DeclSyntax] {
        // Validate: must be on a function
        guard let funcDecl = declaration.as(FunctionDeclSyntax.self) else {
            context.diagnose(
                Diagnostic(
                    node: declaration,
                    message: GherkinDiagnostic.stepRequiresFunction
                ))
            return []
        }

        // Extract the expression string from the first argument
        guard let arguments = node.arguments?.as(LabeledExprListSyntax.self),
            let firstArg = arguments.first,
            let stringLiteral = firstArg.expression.as(StringLiteralExprSyntax.self),
            let expression = SyntaxHelpers.extractStringLiteral(from: stringLiteral)
        else {
            context.diagnose(
                Diagnostic(
                    node: node,
                    message: GherkinDiagnostic.stepExpressionNotStringLiteral
                ))
            return []
        }

        // Validate: expression must not be empty
        if SyntaxHelpers.trimWhitespace(expression).isEmpty {
            context.diagnose(
                Diagnostic(
                    node: node,
                    message: GherkinDiagnostic.stepExpressionEmpty
                ))
            return []
        }

        let funcName = SyntaxHelpers.functionName(from: funcDecl)
        let paramCount = SyntaxHelpers.parameterCount(from: funcDecl)
        let paramNames = SyntaxHelpers.parameterNames(from: funcDecl)
        let captureCount = SyntaxHelpers.captureGroupCount(in: expression)

        let (stepArgKind, effectiveParamCount) = detectStepArgKind(
            funcDecl: funcDecl, paramCount: paramCount, captureCount: captureCount
        )

        // Validate parameter count matches capture groups
        if captureCount != effectiveParamCount {
            context.diagnose(
                Diagnostic(
                    node: funcDecl.signature.parameterClause,
                    message: GherkinDiagnostic.stepParameterCountMismatch
                ))
            return []
        }

        let spec = StepRegistryCodeGen.StepSpec(
            funcName: funcName,
            expression: expression,
            kind: kind,
            paramCount: paramCount,
            isAsync: SyntaxHelpers.isAsync(funcDecl),
            isThrows: SyntaxHelpers.isThrows(funcDecl),
            isMutating: SyntaxHelpers.isMutating(funcDecl),
            paramNames: paramNames,
            stepArgKind: stepArgKind
        )
        return [StepRegistryCodeGen.generateStepDefinition(spec: spec)]
    }

    /// Detects whether the last parameter is a DataTable or DocString receiver.
    ///
    /// - Parameters:
    ///   - funcDecl: The function declaration to inspect.
    ///   - paramCount: The total number of parameters.
    ///   - captureCount: The number of capture groups in the expression.
    /// - Returns: The detected step argument kind and the effective parameter count for validation.
    private static func detectStepArgKind(
        funcDecl: FunctionDeclSyntax,
        paramCount: Int,
        captureCount: Int
    ) -> (StepRegistryCodeGen.StepArgKind?, Int) {
        let lastParamType = SyntaxHelpers.lastParameterTypeName(from: funcDecl)

        if lastParamType == "DataTable" {
            return (.dataTable, paramCount - 1)
        } else if lastParamType == "String" && paramCount == captureCount + 1 {
            return (.docString, paramCount - 1)
        }
        return (nil, paramCount)
    }
}

// MARK: - Concrete Step Macros

/// Macro implementation for `@Given("expression")`.
///
/// Generates a `static let __stepDef_<funcName>` with `keywordType: .context`.
public struct GivenMacro: PeerMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingPeersOf declaration: some DeclSyntaxProtocol,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        try StepMacroBase.expansion(
            of: node, providingPeersOf: declaration, in: context, kind: .given
        )
    }
}

/// Macro implementation for `@When("expression")`.
///
/// Generates a `static let __stepDef_<funcName>` with `keywordType: .action`.
public struct WhenMacro: PeerMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingPeersOf declaration: some DeclSyntaxProtocol,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        try StepMacroBase.expansion(
            of: node, providingPeersOf: declaration, in: context, kind: .when
        )
    }
}

/// Macro implementation for `@Then("expression")`.
///
/// Generates a `static let __stepDef_<funcName>` with `keywordType: .outcome`.
public struct ThenMacro: PeerMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingPeersOf declaration: some DeclSyntaxProtocol,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        try StepMacroBase.expansion(
            of: node, providingPeersOf: declaration, in: context, kind: .then
        )
    }
}

/// Macro implementation for `@And("expression")`.
///
/// Generates a `static let __stepDef_<funcName>` with `keywordType: .conjunction`.
public struct AndMacro: PeerMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingPeersOf declaration: some DeclSyntaxProtocol,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        try StepMacroBase.expansion(
            of: node, providingPeersOf: declaration, in: context, kind: .and
        )
    }
}

/// Macro implementation for `@But("expression")`.
///
/// Generates a `static let __stepDef_<funcName>` with `keywordType: .conjunction`.
public struct ButMacro: PeerMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingPeersOf declaration: some DeclSyntaxProtocol,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        try StepMacroBase.expansion(
            of: node, providingPeersOf: declaration, in: context, kind: .but
        )
    }
}
