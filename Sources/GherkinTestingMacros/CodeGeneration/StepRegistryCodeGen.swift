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

    /// Generates a `static let __stepDef_<name>` declaration for a step definition.
    ///
    /// - Parameters:
    ///   - funcName: The name of the annotated function.
    ///   - expression: The Cucumber expression string.
    ///   - kind: The step keyword kind (given/when/then/and/but).
    ///   - paramCount: The number of function parameters.
    ///   - isAsync: Whether the function is async.
    ///   - isThrows: Whether the function throws.
    ///   - isMutating: Whether the function is mutating.
    ///   - paramNames: The parameter external names.
    /// - Returns: A `DeclSyntax` for the static step definition property.
    static func generateStepDefinition(
        funcName: String,
        expression: String,
        kind: StepKind,
        paramCount: Int,
        isAsync: Bool,
        isThrows: Bool,
        isMutating: Bool,
        paramNames: [String]
    ) -> DeclSyntax {
        let patternCode = generatePatternCode(expression: expression)
        let handlerBody = generateHandlerBody(
            funcName: funcName,
            paramCount: paramCount,
            isAsync: isAsync,
            isThrows: isThrows,
            isMutating: isMutating,
            paramNames: paramNames
        )

        return """
            static let __stepDef_\(raw: funcName) = StepDefinition<Self>(
                keywordType: \(raw: kind.keywordTypeLiteral),
                pattern: \(raw: patternCode),
                sourceLocation: Location(line: 0, column: 0),
                handler: { \(raw: isMutating ? "" : "_ ")feature, args in \(raw: handlerBody) }
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
    /// - Parameters:
    ///   - funcName: The function name.
    ///   - paramCount: Number of parameters.
    ///   - isAsync: Whether async.
    ///   - isThrows: Whether throws.
    ///   - isMutating: Whether mutating.
    ///   - paramNames: Parameter external names.
    /// - Returns: A string of Swift code for the handler closure body.
    static func generateHandlerBody(
        funcName: String,
        paramCount: Int,
        isAsync: Bool,
        isThrows: Bool,
        isMutating: Bool,
        paramNames: [String]
    ) -> String {
        let tryPrefix = isThrows ? "try " : ""
        let awaitPrefix = isAsync ? "await " : ""
        let prefix = "\(tryPrefix)\(awaitPrefix)"

        if paramCount == 0 {
            return "\(prefix)feature.\(funcName)()"
        }

        let argList = (0..<paramCount).map { i in
            let name = paramNames[i]
            let label = name == "_" ? "" : "\(name): "
            return "\(label)args[\(i)]"
        }.joined(separator: ", ")

        return "\(prefix)feature.\(funcName)(\(argList))"
    }

    /// Generates the `__stepDefinitions` static computed property.
    ///
    /// Collects all `__stepDef_*` properties into an array.
    ///
    /// - Parameter funcNames: The names of all step-annotated functions.
    /// - Returns: A `DeclSyntax` for the static property.
    static func generateStepDefinitionsProperty(funcNames: [String]) -> DeclSyntax {
        let elements = funcNames
            .map { "__stepDef_\($0)" }
            .joined(separator: ", ")
        return """
            static var __stepDefinitions: [StepDefinition<Self>] {
                [\(raw: elements)]
            }
            """
    }
}
