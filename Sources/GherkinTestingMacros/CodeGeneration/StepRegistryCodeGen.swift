// StepRegistryCodeGen.swift
// GherkinTestingMacros
//
// Copyright © 2026 Atelier Socle. MIT License.

import SwiftSyntax
import SwiftSyntaxBuilder

/// Generates `StepDefinition` static properties and `__stepDefinitions` aggregations.
enum StepRegistryCodeGen {

    /// The keyword type mapping for each step macro.
    enum StepKind: String {
        case given
        case when
        case then
        case and
        case but

        /// The `StepKeywordType` case name for code generation.
        var keywordTypeLiteral: String {
            switch self {
            case .given: return ".context"
            case .when: return ".action"
            case .then: return ".outcome"
            case .and: return ".conjunction"
            case .but: return ".conjunction"
            }
        }
    }

    /// Groups all parameters needed to generate a step definition.
    struct StepSpec {
        let funcName: String
        let expression: String
        let kind: StepKind
        let paramCount: Int
        let isAsync: Bool
        let isThrows: Bool
        let isMutating: Bool
        let paramNames: [String]
    }

    /// Generates a `static let __stepDef_<name>` declaration for a step definition.
    ///
    /// - Parameter spec: The step definition specification.
    /// - Returns: A `DeclSyntax` for the static step definition property.
    static func generateStepDefinition(spec: StepSpec) -> DeclSyntax {
        let patternCode = generatePatternCode(expression: spec.expression)
        let handlerBody = generateHandlerBody(spec: spec)

        return """
            static let __stepDef_\(raw: spec.funcName) = StepDefinition<Self>(
                keywordType: \(raw: spec.kind.keywordTypeLiteral),
                pattern: \(raw: patternCode),
                sourceLocation: Location(line: 0, column: 0),
                handler: { feature, args in \(raw: handlerBody) }
            )
            """
    }

    /// Generates the `StepPattern` code for an expression.
    ///
    /// Detects the expression type (exact, Cucumber expression, or regex)
    /// and generates the appropriate `StepPattern` case.
    ///
    /// - Parameter expression: The step expression string.
    /// - Returns: A string of Swift code for the pattern.
    static func generatePatternCode(expression: String) -> String {
        let kind = SyntaxHelpers.detectExpressionKind(expression)
        let escaped = SyntaxHelpers.escapeForStringLiteral(expression)

        switch kind {
        case .exact:
            return ".exact(\"\(escaped)\")"
        case .cucumberExpression:
            return ".cucumberExpression(\"\(escaped)\")"
        case .regex:
            return ".regex(\"\(escaped)\")"
        }
    }

    /// Generates the handler body that calls the annotated function.
    ///
    /// - Parameter spec: The step definition specification.
    /// - Returns: A string of Swift code for the handler closure body.
    static func generateHandlerBody(spec: StepSpec) -> String {
        let tryPrefix = spec.isThrows ? "try " : ""
        let awaitPrefix = spec.isAsync ? "await " : ""
        let prefix = "\(tryPrefix)\(awaitPrefix)"

        if spec.paramCount == 0 {
            return "\(prefix)feature.\(spec.funcName)()"
        }

        let argList = (0..<spec.paramCount).map { i in
            let name = spec.paramNames[i]
            let label = name == "_" ? "" : "\(name): "
            return "\(label)args[\(i)]"
        }.joined(separator: ", ")

        return "\(prefix)feature.\(spec.funcName)(\(argList))"
    }

    /// Generates the `__stepDefinitions` static computed property.
    ///
    /// Collects all `__stepDef_*` properties into an array.
    ///
    /// - Parameter funcNames: The names of all step-annotated functions.
    /// - Returns: A `DeclSyntax` for the static property.
    static func generateStepDefinitionsProperty(funcNames: [String]) -> DeclSyntax {
        let elements =
            funcNames
            .map { "__stepDef_\($0)" }
            .joined(separator: ", ")
        return """
            static var __stepDefinitions: [StepDefinition<Self>] {
                [\(raw: elements)]
            }
            """
    }
}
