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

import SwiftSyntax
import SwiftSyntaxMacroExpansion
import SwiftSyntaxMacros
import SwiftSyntaxMacrosGenericTestSupport
import Testing

/// Asserts that expanding the given macros in `originalSource` produces
/// `expectedExpandedSource`, reporting any mismatch through Swift Testing.
///
/// The `assertMacroExpansion` shipped in `SwiftSyntaxMacrosTestSupport` routes
/// failures through `XCTFail`, which the Swift Testing (`@Test`) runner does
/// not observe — so a mismatched expansion would silently report "passed".
/// This wrapper calls the framework-agnostic implementation from
/// `SwiftSyntaxMacrosGenericTestSupport` and forwards failures to
/// `Issue.record`, so macro-expansion assertions genuinely fail the test.
///
/// - Parameters:
///   - originalSource: The source code containing macros to expand.
///   - expectedExpandedSource: The source code expected after expansion.
///   - diagnostics: The diagnostics expected during expansion.
///   - macros: The macros to expand, mapping macro name to implementation type.
///   - applyFixIts: If set, only Fix-Its whose message is in this list are applied.
///   - expectedFixedSource: If set, the source expected after applying Fix-Its.
///   - testModuleName: The module name used during expansion.
///   - testFileName: The file name used during expansion.
///   - indentationWidth: The indentation width used in the expansion.
///   - sourceLocation: The call site, used to anchor recorded issues.
func assertMacroExpansion(
    _ originalSource: String,
    expandedSource expectedExpandedSource: String,
    diagnostics: [DiagnosticSpec] = [],
    macros: [String: any Macro.Type],
    applyFixIts: [String]? = nil,
    fixedSource expectedFixedSource: String? = nil,
    testModuleName: String = "TestModule",
    testFileName: String = "test.swift",
    indentationWidth: Trivia = .spaces(4),
    sourceLocation: Testing.SourceLocation = #_sourceLocation
) {
    let macroSpecs = macros.mapValues { MacroSpec(type: $0) }
    SwiftSyntaxMacrosGenericTestSupport.assertMacroExpansion(
        originalSource,
        expandedSource: expectedExpandedSource,
        diagnostics: diagnostics,
        macroSpecs: macroSpecs,
        applyFixIts: applyFixIts,
        fixedSource: expectedFixedSource,
        testModuleName: testModuleName,
        testFileName: testFileName,
        indentationWidth: indentationWidth,
        failureHandler: { failure in
            Issue.record(
                Comment(rawValue: failure.message),
                sourceLocation: sourceLocation
            )
        }
    )
}
