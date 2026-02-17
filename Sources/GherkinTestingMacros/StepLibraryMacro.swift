// SPDX-License-Identifier: Apache-2.0
//
// Copyright 2026 Atelier Socle SAS
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import SwiftDiagnostics
import SwiftSyntax
import SwiftSyntaxMacros

/// Macro implementation for `@StepLibrary`.
///
/// `@StepLibrary` is both a `MemberMacro` and an `ExtensionMacro`:
/// - **MemberMacro**: Adds a `static var __stepDefinitions` property that collects
///   all `__stepDef_*` static properties from step-annotated functions.
/// - **ExtensionMacro**: Adds `StepLibrary` protocol conformance.
public struct StepLibraryMacro: MemberMacro, ExtensionMacro {

    // MARK: - MemberMacro

    public static func expansion(
        of node: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        conformingTo protocols: [TypeSyntax],
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        guard let structDecl = declaration.as(StructDeclSyntax.self) else {
            context.diagnose(
                Diagnostic(
                    node: declaration,
                    message: GherkinDiagnostic.stepLibraryRequiresStruct
                ))
            return []
        }

        let funcNames = collectStepFuncNames(from: structDecl)
        let decl = StepRegistryCodeGen.generateStepDefinitionsProperty(funcNames: funcNames)
        return [decl]
    }

    // MARK: - ExtensionMacro

    public static func expansion(
        of node: AttributeSyntax,
        attachedTo declaration: some DeclGroupSyntax,
        providingExtensionsOf type: some TypeSyntaxProtocol,
        conformingTo protocols: [TypeSyntax],
        in context: some MacroExpansionContext
    ) throws -> [ExtensionDeclSyntax] {
        guard declaration.is(StructDeclSyntax.self) else {
            return []
        }

        let ext: DeclSyntax = """
            extension \(type.trimmed): StepLibrary {}
            """

        guard let extensionDecl = ext.as(ExtensionDeclSyntax.self) else {
            return []
        }

        return [extensionDecl]
    }

    /// Collects function names that have step macro attributes.
    private static func collectStepFuncNames(from structDecl: StructDeclSyntax) -> [String] {
        let stepAttributeNames: Set<String> = ["Given", "When", "Then", "And", "But"]
        var names: [String] = []

        for member in structDecl.memberBlock.members {
            guard let funcDecl = member.decl.as(FunctionDeclSyntax.self) else { continue }

            let hasStepAttr = funcDecl.attributes.contains { attrElement in
                guard case .attribute(let attr) = attrElement,
                    let identifier = attr.attributeName.as(IdentifierTypeSyntax.self)
                else {
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
}
