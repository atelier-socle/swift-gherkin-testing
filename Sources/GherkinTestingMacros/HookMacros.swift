// HookMacros.swift
// GherkinTestingMacros
//
// Copyright © 2026 Atelier Socle. MIT License.

import SwiftSyntax
import SwiftSyntaxMacros
import SwiftDiagnostics

/// Base implementation shared by `@Before` and `@After` hook macros.
///
/// Hook macros are `PeerMacro`s that generate `static let __hook_<funcName>`
/// declarations containing a `Hook` value with the specified scope.
enum HookMacroBase {

    /// Whether this is a before or after hook.
    enum HookTiming: String {
        case before
        case after
    }

    /// Expands a hook macro into a `Hook` static property.
    ///
    /// - Parameters:
    ///   - node: The attribute syntax node.
    ///   - declaration: The declaration the macro is attached to.
    ///   - context: The macro expansion context.
    ///   - timing: Whether this is a before or after hook.
    /// - Returns: An array of peer declarations.
    static func expansion(
        of node: AttributeSyntax,
        providingPeersOf declaration: some DeclSyntaxProtocol,
        in context: some MacroExpansionContext,
        timing: HookTiming
    ) throws -> [DeclSyntax] {
        // Validate: must be on a function
        guard let funcDecl = declaration.as(FunctionDeclSyntax.self) else {
            context.diagnose(Diagnostic(
                node: declaration,
                message: GherkinDiagnostic.hookRequiresFunction
            ))
            return []
        }

        // Validate: must be static
        guard SyntaxHelpers.isStatic(funcDecl) else {
            context.diagnose(Diagnostic(
                node: funcDecl,
                message: GherkinDiagnostic.hookRequiresStaticFunction
            ))
            return []
        }

        let funcName = SyntaxHelpers.functionName(from: funcDecl)
        let isAsync = SyntaxHelpers.isAsync(funcDecl)
        let isThrows = SyntaxHelpers.isThrows(funcDecl)

        // Parse scope from arguments: @Before(.scenario) or @Before(.feature) or @Before(.step)
        let scope = extractScope(from: node) ?? "scenario"

        // Validate scope
        let validScopes: Set<String> = ["feature", "scenario", "step"]
        guard validScopes.contains(scope) else {
            context.diagnose(Diagnostic(
                node: node,
                message: GherkinDiagnostic.hookInvalidScope
            ))
            return []
        }

        // Parse optional tag filter
        let tagFilterExpr = extractTagFilter(from: node)

        // Parse optional order
        let order = extractOrder(from: node) ?? 0

        let tryPrefix = isThrows ? "try " : ""
        let awaitPrefix = isAsync ? "await " : ""
        let callPrefix = "\(tryPrefix)\(awaitPrefix)"

        let tagFilterCode: String
        if let filter = tagFilterExpr {
            let escaped = SyntaxHelpers.escapeForStringLiteral(filter)
            tagFilterCode = "try? TagFilter(\"\(escaped)\")"
        } else {
            tagFilterCode = "nil"
        }

        let decl: DeclSyntax = """
            static let __hook_\(raw: funcName) = Hook(
                scope: .\(raw: scope),
                order: \(raw: order),
                tagFilter: \(raw: tagFilterCode),
                handler: { \(raw: callPrefix)\(raw: funcName)() }
            )
            """

        return [decl]
    }

    /// Extracts the scope string from the macro arguments.
    ///
    /// Looks for the first positional argument like `.scenario`, `.feature`, or `.step`.
    private static func extractScope(from node: AttributeSyntax) -> String? {
        guard let arguments = node.arguments?.as(LabeledExprListSyntax.self) else {
            return nil
        }

        // First unlabeled argument or 'scope:' labeled argument
        for arg in arguments {
            if arg.label == nil || arg.label?.text == "scope" {
                if let memberAccess = arg.expression.as(MemberAccessExprSyntax.self) {
                    return memberAccess.declName.baseName.text
                }
            }
        }

        return nil
    }

    /// Extracts the order value from the macro arguments.
    ///
    /// Looks for an 'order:' labeled argument.
    private static func extractOrder(from node: AttributeSyntax) -> Int? {
        guard let arguments = node.arguments?.as(LabeledExprListSyntax.self) else {
            return nil
        }

        for arg in arguments {
            if arg.label?.text == "order" {
                if let intLiteral = arg.expression.as(IntegerLiteralExprSyntax.self) {
                    return Int(intLiteral.literal.text)
                }
                // Handle negative: PrefixOperatorExprSyntax("-") wrapping IntegerLiteralExprSyntax
                if let prefix = arg.expression.as(PrefixOperatorExprSyntax.self),
                   prefix.operator.text == "-",
                   let intLiteral = prefix.expression.as(IntegerLiteralExprSyntax.self),
                   let value = Int(intLiteral.literal.text) {
                    return -value
                }
            }
        }

        return nil
    }

    /// Extracts the tag filter string from the macro arguments.
    ///
    /// Looks for a 'tags:' labeled argument.
    private static func extractTagFilter(from node: AttributeSyntax) -> String? {
        guard let arguments = node.arguments?.as(LabeledExprListSyntax.self) else {
            return nil
        }

        for arg in arguments {
            if arg.label?.text == "tags" {
                if let stringLiteral = arg.expression.as(StringLiteralExprSyntax.self) {
                    return SyntaxHelpers.extractStringLiteral(from: stringLiteral)
                }
            }
        }

        return nil
    }
}

// MARK: - Concrete Hook Macros

/// Macro implementation for `@Before(.scope)`.
///
/// Generates a `static let __hook_<funcName>` with a `Hook` value
/// that executes before the specified scope.
public struct BeforeMacro: PeerMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingPeersOf declaration: some DeclSyntaxProtocol,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        try HookMacroBase.expansion(
            of: node, providingPeersOf: declaration, in: context, timing: .before
        )
    }
}

/// Macro implementation for `@After(.scope)`.
///
/// Generates a `static let __hook_<funcName>` with a `Hook` value
/// that executes after the specified scope.
public struct AfterMacro: PeerMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingPeersOf declaration: some DeclSyntaxProtocol,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        try HookMacroBase.expansion(
            of: node, providingPeersOf: declaration, in: context, timing: .after
        )
    }
}
