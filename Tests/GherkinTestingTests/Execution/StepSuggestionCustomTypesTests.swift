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

import Testing

@testable import GherkinTesting

@Suite("StepSuggestion Custom Types")
struct StepSuggestionCustomTypesTests {

    // MARK: - Custom Type Names in Suggestions

    @Test("suggestion with custom type names appends comment")
    func customTypeComment() {
        let suggestion = StepSuggestion.suggest(
            stepText: "the item is red",
            customTypeNames: ["color", "amount"]
        )
        #expect(suggestion.suggestedSignature.contains("// Available custom types: {color}, {amount}"))
    }

    @Test("suggestion with single custom type name")
    func singleCustomType() {
        let suggestion = StepSuggestion.suggest(
            stepText: "the item is red",
            customTypeNames: ["color"]
        )
        #expect(suggestion.suggestedSignature.contains("// Available custom types: {color}"))
    }

    @Test("suggestion with empty custom type names has no comment")
    func emptyCustomTypes() {
        let suggestion = StepSuggestion.suggest(
            stepText: "the item is red",
            customTypeNames: []
        )
        #expect(!suggestion.suggestedSignature.contains("// Available custom types"))
    }

    @Test("default parameter omits comment")
    func defaultParameter() {
        let suggestion = StepSuggestion.suggest(stepText: "the item is red")
        #expect(!suggestion.suggestedSignature.contains("// Available custom types"))
    }

    // MARK: - Pattern Analysis Unaffected

    @Test("analysis still detects int with custom types present")
    func analysisWithCustomTypes() {
        let suggestion = StepSuggestion.suggest(
            stepText: "the user has 42 items",
            customTypeNames: ["color"]
        )
        #expect(suggestion.suggestedExpression == "the user has {int} items")
        #expect(suggestion.suggestedSignature.contains("// Available custom types: {color}"))
    }

    @Test("analysis still detects string with custom types present")
    func analysisStringWithCustomTypes() {
        let suggestion = StepSuggestion.suggest(
            stepText: "the user enters \"hello\"",
            customTypeNames: ["color", "amount"]
        )
        #expect(suggestion.suggestedExpression == "the user enters {string}")
    }

    // MARK: - Keyword Type Preserved

    @Test("keyword type and custom types work together")
    func keywordAndCustomTypes() {
        let suggestion = StepSuggestion.suggest(
            stepText: "the item is red",
            keywordType: .outcome,
            customTypeNames: ["color"]
        )
        #expect(suggestion.suggestedSignature.contains("@Then"))
        #expect(suggestion.suggestedSignature.contains("// Available custom types: {color}"))
    }
}
