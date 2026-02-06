// FeatureMacro.swift
// GherkinTestingMacros
//
// Copyright © 2026 Atelier Socle. MIT License.

import SwiftSyntax
import SwiftSyntaxMacros
import SwiftDiagnostics

/// Macro implementation for `@Feature(source:)`.
///
/// `@Feature` is an `@attached(peer)` macro that generates:
/// 1. An `extension TypeName: GherkinFeature {}` conformance
/// 2. A `@Suite` struct with `@Test` methods that execute the feature's scenarios
///
/// For `.inline(...)` sources, scenario names are extracted at compile time
/// to generate per-scenario `@Test` methods. For `.file(...)` sources, a single
/// `@Test` method is generated that parses the file at runtime.
public struct FeatureMacro: PeerMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingPeersOf declaration: some DeclSyntaxProtocol,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        // Validate: must be on a struct
        guard let structDecl = declaration.as(StructDeclSyntax.self) else {
            context.diagnose(Diagnostic(
                node: declaration,
                message: GherkinDiagnostic.featureRequiresStruct
            ))
            return []
        }

        let typeName = structDecl.name.text

        // Extract source: argument
        guard let arguments = node.arguments?.as(LabeledExprListSyntax.self),
              let sourceArg = arguments.first(where: { $0.label?.text == "source" }) else {
            context.diagnose(Diagnostic(
                node: node,
                message: GherkinDiagnostic.featureMissingSource
            ))
            return []
        }

        // Parse the source expression: .inline("...") or .file("...")
        guard let funcCall = sourceArg.expression.as(FunctionCallExprSyntax.self),
              let memberAccess = funcCall.calledExpression.as(MemberAccessExprSyntax.self) else {
            context.diagnose(Diagnostic(
                node: sourceArg.expression,
                message: GherkinDiagnostic.featureInvalidSource
            ))
            return []
        }

        let memberName = memberAccess.declName.baseName.text

        // Extract the string argument from .inline("...") or .file("...")
        guard let callArg = funcCall.arguments.first,
              let stringLiteral = callArg.expression.as(StringLiteralExprSyntax.self),
              let stringValue = SyntaxHelpers.extractStringLiteral(from: stringLiteral) else {
            context.diagnose(Diagnostic(
                node: sourceArg.expression,
                message: GherkinDiagnostic.featureInvalidSource
            ))
            return []
        }

        // Collect step function names from the struct's members
        let stepFuncNames = collectStepFuncNames(from: structDecl)

        // Generate __stepDefinitions property
        let stepDefsProp = StepRegistryCodeGen.generateStepDefinitionsProperty(funcNames: stepFuncNames)

        switch memberName {
        case "inline":
            let scenarioNames = SyntaxHelpers.extractScenarioNames(from: stringValue)
            let escapedSource = escapeMultilineString(stringValue)

            var decls: [DeclSyntax] = []

            // GherkinFeature conformance
            let conformanceDecl: DeclSyntax = """
                extension \(raw: typeName): GherkinFeature {}
                """
            decls.append(conformanceDecl)

            // __stepDefinitions as extension member
            let stepDefsExtDecl: DeclSyntax = """
                extension \(raw: typeName) {
                    \(stepDefsProp)
                }
                """
            decls.append(stepDefsExtDecl)

            // @Suite with @Test methods
            let suiteName = "\(typeName)__GherkinTests"

            if scenarioNames.isEmpty {
                let suiteDecl: DeclSyntax = """
                    @Suite("\\(\(raw: typeName).self)")
                    struct \(raw: suiteName) {
                        @Test("Feature: \(raw: typeName)")
                        func feature_test() async throws {
                            try await FeatureExecutor<\(raw: typeName)>.run(
                                source: .inline(\(raw: escapedSource)),
                                definitions: \(raw: typeName).__stepDefinitions,
                                featureFactory: { \(raw: typeName)() }
                            )
                        }
                    }
                    """
                decls.append(suiteDecl)
            } else {
                var methods: [String] = []
                for name in scenarioNames {
                    let methodName = "scenario_\(SyntaxHelpers.sanitizeIdentifier(name))"
                    let escapedName = SyntaxHelpers.escapeForStringLiteral(name)
                    methods.append("""
                            @Test("Scenario: \(escapedName)")
                            func \(methodName)() async throws {
                                try await FeatureExecutor<\(typeName)>.run(
                                    source: .inline(\(escapedSource)),
                                    definitions: \(typeName).__stepDefinitions,
                                    scenarioFilter: "\(escapedName)",
                                    featureFactory: { \(typeName)() }
                                )
                            }
                        """)
                }
                let methodsCode = methods.joined(separator: "\n\n")
                let suiteDecl: DeclSyntax = """
                    @Suite("\\(\(raw: typeName).self)")
                    struct \(raw: suiteName) {
                    \(raw: methodsCode)
                    }
                    """
                decls.append(suiteDecl)
            }

            return decls

        case "file":
            let escapedPath = SyntaxHelpers.escapeForStringLiteral(stringValue)
            let suiteName = "\(typeName)__GherkinTests"

            let conformanceDecl: DeclSyntax = """
                extension \(raw: typeName): GherkinFeature {}
                """

            let stepDefsExtDecl: DeclSyntax = """
                extension \(raw: typeName) {
                    \(stepDefsProp)
                }
                """

            let suiteDecl: DeclSyntax = """
                @Suite("\\(\(raw: typeName).self)")
                struct \(raw: suiteName) {
                    @Test("Feature: \(raw: typeName)")
                    func feature_test() async throws {
                        try await FeatureExecutor<\(raw: typeName)>.run(
                            source: .file("\(raw: escapedPath)"),
                            definitions: \(raw: typeName).__stepDefinitions,
                            featureFactory: { \(raw: typeName)() }
                        )
                    }
                }
                """

            return [conformanceDecl, stepDefsExtDecl, suiteDecl]

        default:
            context.diagnose(Diagnostic(
                node: sourceArg.expression,
                message: GherkinDiagnostic.featureInvalidSource
            ))
            return []
        }
    }

    /// Collects function names that have step macro attributes (@Given, @When, @Then, @And, @But).
    private static func collectStepFuncNames(from structDecl: StructDeclSyntax) -> [String] {
        let stepAttributeNames: Set<String> = ["Given", "When", "Then", "And", "But"]
        var names: [String] = []

        for member in structDecl.memberBlock.members {
            guard let funcDecl = member.decl.as(FunctionDeclSyntax.self) else { continue }

            let hasStepAttr = funcDecl.attributes.contains { attrElement in
                guard case .attribute(let attr) = attrElement,
                      let identifier = attr.attributeName.as(IdentifierTypeSyntax.self) else {
                    return false
                }
                return stepAttributeNames.contains(identifier.name.text)
            }

            if hasStepAttr {
                names.append(funcDecl.name.text)
            }
        }

        return names
    }

    /// Escapes a multiline string for embedding in generated source code.
    private static func escapeMultilineString(_ string: String) -> String {
        let escaped = SyntaxHelpers.escapeForStringLiteral(string)
        return "\"\(escaped)\""
    }
}
