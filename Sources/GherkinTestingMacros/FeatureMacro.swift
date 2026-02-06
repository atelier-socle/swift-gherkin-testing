// FeatureMacro.swift
// GherkinTestingMacros
//
// Copyright © 2026 Atelier Socle. MIT License.

import SwiftSyntax
import SwiftSyntaxMacros
import SwiftDiagnostics

/// Macro implementation for `@Feature(source:stepLibraries:)`.
///
/// `@Feature` is a multi-role macro:
/// 1. `ExtensionMacro` — generates `extension TypeName: GherkinFeature {}`
/// 2. `MemberMacro` — generates `static var __stepDefinitions` and optionally
///    `static var __hooks` inside the struct
/// 3. `PeerMacro` — generates `struct TypeName__GherkinTests` with `@Suite`/`@Test`
///
/// For `.inline(...)` sources, scenario names are extracted at compile time
/// to generate per-scenario `@Test` methods. For `.file(...)` sources, a single
/// `@Test` method is generated that parses the file at runtime.
///
/// When `stepLibraries:` is provided, each library's step definitions are
/// retyped via `StepDefinition.retyped(for:using:)` and concatenated.
///
/// When `@Before`/`@After` hooks are present on static functions, a `__hooks`
/// property is generated and passed to `FeatureExecutor.run(hooks:)`.
public struct FeatureMacro {}

// MARK: - ExtensionMacro — GherkinFeature conformance

extension FeatureMacro: ExtensionMacro {
    public static func expansion(
        of node: AttributeSyntax,
        attachedTo declaration: some DeclGroupSyntax,
        providingExtensionsOf type: some TypeSyntaxProtocol,
        conformingTo protocols: [TypeSyntax],
        in context: some MacroExpansionContext
    ) throws -> [ExtensionDeclSyntax] {
        guard declaration.is(StructDeclSyntax.self) else { return [] }

        let ext: DeclSyntax = """
            extension \(type.trimmed): GherkinFeature {}
            """
        guard let extDecl = ext.as(ExtensionDeclSyntax.self) else { return [] }
        return [extDecl]
    }
}

// MARK: - MemberMacro — __stepDefinitions + __hooks properties

extension FeatureMacro: MemberMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        conformingTo protocols: [TypeSyntax],
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        guard let structDecl = declaration.as(StructDeclSyntax.self) else { return [] }

        let stepFuncNames = collectStepFuncNames(from: structDecl)
        let libraryTypeNames = extractStepLibraries(from: node)
        let stepDefsProp = generateStepDefinitionsWithLibraries(
            funcNames: stepFuncNames,
            libraryTypeNames: libraryTypeNames
        )

        var members: [DeclSyntax] = [stepDefsProp]

        let hookInfo = collectHookInfo(from: structDecl)
        if !hookInfo.isEmpty {
            members.append(generateHooksProperty(hookInfo: hookInfo))
        }

        return members
    }
}

// MARK: - PeerMacro — __GherkinTests @Suite

extension FeatureMacro: PeerMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingPeersOf declaration: some DeclSyntaxProtocol,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        guard let structDecl = declaration.as(StructDeclSyntax.self) else {
            context.diagnose(Diagnostic(
                node: declaration,
                message: GherkinDiagnostic.featureRequiresStruct
            ))
            return []
        }

        let typeName = structDecl.name.text

        guard let (memberName, stringValue) = extractSourceArgument(from: node, in: context) else {
            return []
        }

        let suiteName = "\(typeName)__GherkinTests"
        let hasHooks = !collectHookInfo(from: structDecl).isEmpty
        let hooksArg = hasHooks ? "\n                        hooks: \(typeName).__hooks," : ""

        switch memberName {
        case "inline":
            let scenarioNames = SyntaxHelpers.extractScenarioNames(from: stringValue)
            let escapedSource = escapeMultilineString(stringValue)

            if scenarioNames.isEmpty {
                let suiteDecl: DeclSyntax = """
                    @Suite("\(raw: typeName)")
                    struct \(raw: suiteName) {
                        @Test("Feature: \(raw: typeName)")
                        func feature_test() async throws {
                            try await FeatureExecutor<\(raw: typeName)>.run(
                                source: .inline(\(raw: escapedSource)),
                                definitions: \(raw: typeName).__stepDefinitions,\(raw: hooksArg)
                                featureFactory: { \(raw: typeName)() }
                            )
                        }
                    }
                    """
                return [suiteDecl]
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
                                    definitions: \(typeName).__stepDefinitions,\(hooksArg)
                                    scenarioFilter: "\(escapedName)",
                                    featureFactory: { \(typeName)() }
                                )
                            }
                        """)
                }
                let methodsCode = methods.joined(separator: "\n\n")
                let suiteDecl: DeclSyntax = """
                    @Suite("\(raw: typeName)")
                    struct \(raw: suiteName) {
                    \(raw: methodsCode)
                    }
                    """
                return [suiteDecl]
            }

        case "file":
            let escapedPath = SyntaxHelpers.escapeForStringLiteral(stringValue)
            let suiteDecl: DeclSyntax = """
                @Suite("\(raw: typeName)")
                struct \(raw: suiteName) {
                    @Test("Feature: \(raw: typeName)")
                    func feature_test() async throws {
                        try await FeatureExecutor<\(raw: typeName)>.run(
                            source: .file("\(raw: escapedPath)"),
                            definitions: \(raw: typeName).__stepDefinitions,\(raw: hooksArg)
                            bundle: Bundle.module,
                            featureFactory: { \(raw: typeName)() }
                        )
                    }
                }
                """
            return [suiteDecl]

        default:
            context.diagnose(Diagnostic(
                node: node,
                message: GherkinDiagnostic.featureInvalidSource
            ))
            return []
        }
    }
}

// MARK: - Shared Helpers

extension FeatureMacro {
    /// Extracts the source argument (memberName, stringValue) from the @Feature attribute.
    static func extractSourceArgument(
        from node: AttributeSyntax,
        in context: some MacroExpansionContext
    ) -> (memberName: String, stringValue: String)? {
        guard let arguments = node.arguments?.as(LabeledExprListSyntax.self),
              let sourceArg = arguments.first(where: { $0.label?.text == "source" }) else {
            context.diagnose(Diagnostic(
                node: node,
                message: GherkinDiagnostic.featureMissingSource
            ))
            return nil
        }

        guard let funcCall = sourceArg.expression.as(FunctionCallExprSyntax.self),
              let memberAccess = funcCall.calledExpression.as(MemberAccessExprSyntax.self) else {
            context.diagnose(Diagnostic(
                node: sourceArg.expression,
                message: GherkinDiagnostic.featureInvalidSource
            ))
            return nil
        }

        let memberName = memberAccess.declName.baseName.text

        guard let callArg = funcCall.arguments.first,
              let stringLiteral = callArg.expression.as(StringLiteralExprSyntax.self),
              let stringValue = SyntaxHelpers.extractStringLiteral(from: stringLiteral) else {
            context.diagnose(Diagnostic(
                node: sourceArg.expression,
                message: GherkinDiagnostic.featureInvalidSource
            ))
            return nil
        }

        return (memberName, stringValue)
    }

    /// Collects function names that have step macro attributes (@Given, @When, @Then, @And, @But).
    static func collectStepFuncNames(from structDecl: StructDeclSyntax) -> [String] {
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

    /// Information about a hook found in the struct.
    struct HookInfo {
        /// The function name (used to reference `__hook_<funcName>`).
        let funcName: String
        /// Whether this is a "before" or "after" hook.
        let timing: String
    }

    /// Collects hook information from functions with @Before/@After attributes.
    static func collectHookInfo(from structDecl: StructDeclSyntax) -> [HookInfo] {
        let hookAttributes: [String: String] = ["Before": "before", "After": "after"]
        var hooks: [HookInfo] = []

        for member in structDecl.memberBlock.members {
            guard let funcDecl = member.decl.as(FunctionDeclSyntax.self) else { continue }

            for attrElement in funcDecl.attributes {
                guard case .attribute(let attr) = attrElement,
                      let identifier = attr.attributeName.as(IdentifierTypeSyntax.self),
                      let timing = hookAttributes[identifier.name.text] else {
                    continue
                }
                hooks.append(HookInfo(funcName: funcDecl.name.text, timing: timing))
            }
        }

        return hooks
    }

    /// Generates the `__hooks` static property from collected hook information.
    static func generateHooksProperty(hookInfo: [HookInfo]) -> DeclSyntax {
        var lines: [String] = ["var registry = HookRegistry()"]
        for info in hookInfo {
            let method = info.timing == "before" ? "addBefore" : "addAfter"
            lines.append("registry.\(method)(__hook_\(info.funcName))")
        }
        lines.append("return registry")
        let body = lines.joined(separator: "\n            ")
        return """
            static var __hooks: HookRegistry {
                \(raw: body)
            }
            """
    }

    /// Extracts step library type names from the @Feature attribute.
    ///
    /// Parses `stepLibraries: [AuthSteps.self, NavSteps.self]` → `["AuthSteps", "NavSteps"]`.
    static func extractStepLibraries(from node: AttributeSyntax) -> [String] {
        guard let arguments = node.arguments?.as(LabeledExprListSyntax.self) else { return [] }
        guard let libArg = arguments.first(where: { $0.label?.text == "stepLibraries" }) else {
            return []
        }
        guard let arrayExpr = libArg.expression.as(ArrayExprSyntax.self) else { return [] }

        var typeNames: [String] = []
        for element in arrayExpr.elements {
            if let memberAccess = element.expression.as(MemberAccessExprSyntax.self),
               memberAccess.declName.baseName.text == "self",
               let base = memberAccess.base?.as(DeclReferenceExprSyntax.self) {
                typeNames.append(base.baseName.text)
            }
        }
        return typeNames
    }

    /// Generates `__stepDefinitions` that includes both local steps and library steps.
    static func generateStepDefinitionsWithLibraries(
        funcNames: [String],
        libraryTypeNames: [String]
    ) -> DeclSyntax {
        if libraryTypeNames.isEmpty {
            return StepRegistryCodeGen.generateStepDefinitionsProperty(funcNames: funcNames)
        }

        let localElements = funcNames.map { "__stepDef_\($0)" }.joined(separator: ", ")
        var lines: [String] = ["var defs: [StepDefinition<Self>] = [\(localElements)]"]
        for libType in libraryTypeNames {
            lines.append(
                "defs += \(libType).__stepDefinitions.map "
                + "{ $0.retyped(for: Self.self, using: { \(libType)() }) }"
            )
        }
        lines.append("return defs")
        let body = lines.joined(separator: "\n            ")
        return """
            static var __stepDefinitions: [StepDefinition<Self>] {
                \(raw: body)
            }
            """
    }

    /// Escapes a multiline string for embedding in generated source code.
    static func escapeMultilineString(_ string: String) -> String {
        let escaped = SyntaxHelpers.escapeForStringLiteral(string)
        return "\"\(escaped)\""
    }
}
