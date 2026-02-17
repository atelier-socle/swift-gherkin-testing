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

/// A feature type for matcher tests.
private struct MatcherFeature: GherkinFeature {
    var log: [String] = []
}

/// Helper to create a PickleStep.
private func pickleStep(_ text: String) -> PickleStep {
    PickleStep(id: "step-1", text: text, argument: nil, astNodeIds: [])
}

/// Helper to create a StepDefinition with an exact pattern.
private func exactDef(
    _ pattern: String,
    line: Int = 1
) -> StepDefinition<MatcherFeature> {
    StepDefinition(
        pattern: .exact(pattern),
        sourceLocation: Location(line: line),
        handler: { _, _, _ in }
    )
}

/// Helper to create a StepDefinition with a cucumber expression.
private func cucumberDef(
    _ expression: String,
    line: Int = 1
) -> StepDefinition<MatcherFeature> {
    StepDefinition(
        pattern: .cucumberExpression(expression),
        sourceLocation: Location(line: line),
        handler: { _, _, _ in }
    )
}

/// Helper to create a StepDefinition with a regex pattern.
private func regexDef(
    _ pattern: String,
    line: Int = 1
) -> StepDefinition<MatcherFeature> {
    StepDefinition(
        pattern: .regex(pattern),
        sourceLocation: Location(line: line),
        handler: { _, _, _ in }
    )
}

@Suite("RegexStepMatcher")
struct RegexStepMatcherTests {

    // MARK: - Priority: Exact > Cucumber > Regex

    @Test("exact match takes priority over cucumber expression")
    func exactOverCucumber() throws {
        let defs: [StepDefinition<MatcherFeature>] = [
            cucumberDef("the user clicks submit", line: 1),
            exactDef("the user clicks submit", line: 2)
        ]
        let matcher = RegexStepMatcher(definitions: defs)
        let match = try matcher.match(pickleStep("the user clicks submit"))
        #expect(match.matchLocation == Location(line: 2))
    }

    @Test("exact match takes priority over regex")
    func exactOverRegex() throws {
        let defs: [StepDefinition<MatcherFeature>] = [
            regexDef("^the user clicks submit$", line: 1),
            exactDef("the user clicks submit", line: 2)
        ]
        let matcher = RegexStepMatcher(definitions: defs)
        let match = try matcher.match(pickleStep("the user clicks submit"))
        #expect(match.matchLocation == Location(line: 2))
    }

    @Test("cucumber expression takes priority over regex")
    func cucumberOverRegex() throws {
        let defs: [StepDefinition<MatcherFeature>] = [
            regexDef("^the user has (\\d+) items$", line: 1),
            cucumberDef("the user has {int} items", line: 2)
        ]
        let matcher = RegexStepMatcher(definitions: defs)
        let match = try matcher.match(pickleStep("the user has 42 items"))
        #expect(match.matchLocation == Location(line: 2))
    }

    // MARK: - Cucumber Expression Matching

    @Test("cucumber expression extracts arguments")
    func cucumberArgs() throws {
        let defs = [cucumberDef("I have {int} cucumber(s)")]
        let matcher = RegexStepMatcher(definitions: defs)
        let match = try matcher.match(pickleStep("I have 5 cucumbers"))
        #expect(match.arguments == ["5"])
    }

    @Test("cucumber expression with {string} strips quotes")
    func cucumberStringStripsQuotes() throws {
        let defs = [cucumberDef("the user enters {string}")]
        let matcher = RegexStepMatcher(definitions: defs)
        let match = try matcher.match(pickleStep("the user enters \"hello\""))
        #expect(match.arguments == ["hello"])
    }

    @Test("cucumber expression with alternation")
    func cucumberAlternation() throws {
        let defs = [cucumberDef("I eat/drink a {word}")]
        let matcher = RegexStepMatcher(definitions: defs)

        let m1 = try matcher.match(pickleStep("I eat a pizza"))
        #expect(m1.arguments == ["pizza"])

        let m2 = try matcher.match(pickleStep("I drink a coffee"))
        #expect(m2.arguments == ["coffee"])
    }

    // MARK: - Regex Matching

    @Test("regex match with capture groups")
    func regexCapture() throws {
        let defs = [regexDef("^the (.+) user has (\\d+) items$")]
        let matcher = RegexStepMatcher(definitions: defs)
        let match = try matcher.match(pickleStep("the admin user has 5 items"))
        #expect(match.arguments == ["admin", "5"])
    }

    @Test("regex match with no capture groups")
    func regexNoCapture() throws {
        let defs = [regexDef("^hello world$")]
        let matcher = RegexStepMatcher(definitions: defs)
        let match = try matcher.match(pickleStep("hello world"))
        #expect(match.arguments.isEmpty)
    }

    // MARK: - Undefined

    @Test("throws undefined when no definitions exist")
    func undefinedEmpty() throws {
        let matcher = RegexStepMatcher<MatcherFeature>(definitions: [])
        #expect {
            try matcher.match(pickleStep("any step"))
        } throws: { error in
            guard let e = error as? StepMatchError else { return false }
            return e == .undefined(stepText: "any step")
        }
    }

    @Test("throws undefined when nothing matches")
    func undefinedNoMatch() throws {
        let defs = [exactDef("step A")]
        let matcher = RegexStepMatcher(definitions: defs)
        #expect {
            try matcher.match(pickleStep("step B"))
        } throws: { error in
            guard let e = error as? StepMatchError else { return false }
            return e == .undefined(stepText: "step B")
        }
    }

    // MARK: - Ambiguous

    @Test("throws ambiguous when two exact patterns match")
    func ambiguousTwoExact() throws {
        let defs = [exactDef("hello", line: 1), exactDef("hello", line: 2)]
        let matcher = RegexStepMatcher(definitions: defs)
        #expect {
            try matcher.match(pickleStep("hello"))
        } throws: { error in
            guard let e = error as? StepMatchError,
                case .ambiguous(let text, let descs) = e
            else { return false }
            return text == "hello" && descs.count == 2
        }
    }

    @Test("throws ambiguous when two cucumber expressions match at same priority")
    func ambiguousTwoCucumber() throws {
        let defs = [
            cucumberDef("I have {int} items", line: 1),
            cucumberDef("I have {} items", line: 2)
        ]
        let matcher = RegexStepMatcher(definitions: defs)
        #expect {
            try matcher.match(pickleStep("I have 5 items"))
        } throws: { error in
            guard let e = error as? StepMatchError,
                case .ambiguous = e
            else { return false }
            return true
        }
    }

    @Test("does not throw ambiguous when different priority levels")
    func notAmbiguousDiffPriority() throws {
        let defs: [StepDefinition<MatcherFeature>] = [
            exactDef("hello world", line: 1),
            regexDef("^hello world$", line: 2)
        ]
        let matcher = RegexStepMatcher(definitions: defs)
        let match = try matcher.match(pickleStep("hello world"))
        #expect(match.matchLocation == Location(line: 1))
    }

    // MARK: - Custom Registry

    @Test("uses custom parameter type from registry")
    func customRegistry() throws {
        var registry = ParameterTypeRegistry()
        try registry.registerAny(
            AnyParameterType(
                name: "color",
                regexps: ["red|green|blue"],
                transformer: { $0 }
            ))

        let defs = [cucumberDef("the {color} button")]
        let matcher = RegexStepMatcher(definitions: defs, registry: registry)
        let match = try matcher.match(pickleStep("the red button"))
        #expect(match.arguments == ["red"])
    }

    // MARK: - Edge Cases

    @Test("empty step text matches empty exact pattern")
    func emptyStepText() throws {
        let defs = [exactDef("")]
        let matcher = RegexStepMatcher(definitions: defs)
        let match = try matcher.match(pickleStep(""))
        #expect(match.arguments.isEmpty)
    }

    @Test("invalid regex pattern does not match")
    func invalidRegex() throws {
        let defs = [regexDef("[invalid")]
        let matcher = RegexStepMatcher(definitions: defs)
        #expect(throws: StepMatchError.self) {
            try matcher.match(pickleStep("anything"))
        }
    }

    @Test("special regex characters in exact match")
    func specialCharsExact() throws {
        let defs = [exactDef("the price is $9.99 (USD)")]
        let matcher = RegexStepMatcher(definitions: defs)
        let match = try matcher.match(pickleStep("the price is $9.99 (USD)"))
        #expect(match.arguments.isEmpty)
    }
}
