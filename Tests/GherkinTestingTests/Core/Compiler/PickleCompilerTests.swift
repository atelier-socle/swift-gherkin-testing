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

@Suite("PickleCompiler — Simple Scenario Tests")
struct PickleCompilerSimpleTests {

    let compiler = PickleCompiler()
    let parser = GherkinParser()

    @Test("Simple scenario produces one pickle")
    func simpleScenario() throws {
        let source = """
            Feature: Simple
              Scenario: S1
                Given step 1
                When step 2
                Then step 3
            """
        let doc = try parser.parse(source: source)
        let pickles = compiler.compile(doc)
        #expect(pickles.count == 1)
        #expect(pickles[0].name == "S1")
        #expect(pickles[0].steps.count == 3)
        #expect(pickles[0].steps[0].text == "step 1")
        #expect(pickles[0].steps[1].text == "step 2")
        #expect(pickles[0].steps[2].text == "step 3")
    }

    @Test("Empty scenario produces one pickle with zero steps")
    func emptyScenario() throws {
        let source = """
            Feature: Empty
              Scenario: No steps
            """
        let doc = try parser.parse(source: source)
        let pickles = compiler.compile(doc)
        #expect(pickles.count == 1)
        #expect(pickles[0].name == "No steps")
        #expect(pickles[0].steps.isEmpty)
    }

    @Test("Multiple scenarios produce multiple pickles")
    func multipleScenarios() throws {
        let source = """
            Feature: Multi
              Scenario: S1
                Given a
              Scenario: S2
                Given b
              Scenario: S3
                Given c
            """
        let doc = try parser.parse(source: source)
        let pickles = compiler.compile(doc)
        #expect(pickles.count == 3)
        #expect(pickles[0].name == "S1")
        #expect(pickles[1].name == "S2")
        #expect(pickles[2].name == "S3")
    }

    @Test("No feature produces no pickles")
    func noFeature() throws {
        let doc = try parser.parse(source: "# just a comment")
        let pickles = compiler.compile(doc)
        #expect(pickles.isEmpty)
    }

    @Test("URI is passed through to pickles")
    func uriPassthrough() throws {
        let source = """
            Feature: URI
              Scenario: S1
                Given step
            """
        let doc = try parser.parse(source: source)
        let pickles = compiler.compile(doc, uri: "features/login.feature")
        #expect(pickles[0].uri == "features/login.feature")
    }

    @Test("Language is set from feature")
    func language() throws {
        let source = """
            # language: fr
            Fonctionnalité: Test
              Scénario: S1
                Soit un truc
            """
        let doc = try parser.parse(source: source)
        let pickles = compiler.compile(doc)
        #expect(pickles[0].language == "fr")
    }
}

@Suite("PickleCompiler — Background Merging Tests")
struct PickleCompilerBackgroundTests {

    let compiler = PickleCompiler()
    let parser = GherkinParser()

    @Test("Feature background steps prepended to scenario")
    func featureBackground() throws {
        let source = """
            Feature: BG
              Background:
                Given bg step 1
                And bg step 2

              Scenario: S1
                When action
                Then result
            """
        let doc = try parser.parse(source: source)
        let pickles = compiler.compile(doc)
        #expect(pickles.count == 1)
        #expect(pickles[0].steps.count == 4)
        #expect(pickles[0].steps[0].text == "bg step 1")
        #expect(pickles[0].steps[1].text == "bg step 2")
        #expect(pickles[0].steps[2].text == "action")
        #expect(pickles[0].steps[3].text == "result")
    }

    @Test("Background applies to all scenarios in feature")
    func backgroundAppliedToAll() throws {
        let source = """
            Feature: BG multi
              Background:
                Given setup

              Scenario: S1
                When action 1
              Scenario: S2
                When action 2
            """
        let doc = try parser.parse(source: source)
        let pickles = compiler.compile(doc)
        #expect(pickles.count == 2)
        #expect(pickles[0].steps[0].text == "setup")
        #expect(pickles[0].steps[1].text == "action 1")
        #expect(pickles[1].steps[0].text == "setup")
        #expect(pickles[1].steps[1].text == "action 2")
    }

    @Test("Rule background merged after feature background")
    func ruleBackground() throws {
        let source = """
            Feature: Rule BG
              Background:
                Given feature setup

              Rule: R1
                Background:
                  Given rule setup

                Scenario: S1
                  When action
            """
        let doc = try parser.parse(source: source)
        let pickles = compiler.compile(doc)
        #expect(pickles.count == 1)
        #expect(pickles[0].steps.count == 3)
        #expect(pickles[0].steps[0].text == "feature setup")
        #expect(pickles[0].steps[1].text == "rule setup")
        #expect(pickles[0].steps[2].text == "action")
    }

    @Test("Background only applies to scenarios after it in children order")
    func backgroundOrder() throws {
        let source = """
            Feature: Order
              Scenario: Before BG
                Given step

              Background:
                Given bg step

              Scenario: After BG
                Given step
            """
        let doc = try parser.parse(source: source)
        let pickles = compiler.compile(doc)
        #expect(pickles.count == 2)
        // Scenario before background: no bg steps
        #expect(pickles[0].steps.count == 1)
        #expect(pickles[0].steps[0].text == "step")
        // Scenario after background: bg steps prepended
        #expect(pickles[1].steps.count == 2)
        #expect(pickles[1].steps[0].text == "bg step")
        #expect(pickles[1].steps[1].text == "step")
    }
}

@Suite("PickleCompiler — Tag Inheritance Tests")
struct PickleCompilerTagTests {

    let compiler = PickleCompiler()
    let parser = GherkinParser()

    @Test("Feature tags inherited by scenario")
    func featureTags() throws {
        let source = """
            @feature-tag
            Feature: Tags
              Scenario: S1
                Given step
            """
        let doc = try parser.parse(source: source)
        let pickles = compiler.compile(doc)
        #expect(pickles[0].tags.count == 1)
        #expect(pickles[0].tags[0].name == "@feature-tag")
    }

    @Test("Tags from all levels combined")
    func allLevelTags() throws {
        let source = """
            @ftag
            Feature: Tags
              @rtag
              Rule: R1
                @stag
                Scenario: S1
                  Given step
            """
        let doc = try parser.parse(source: source)
        let pickles = compiler.compile(doc)
        let tagNames = pickles[0].tags.map(\.name)
        #expect(tagNames.contains("@ftag"))
        #expect(tagNames.contains("@rtag"))
        #expect(tagNames.contains("@stag"))
        #expect(tagNames.count == 3)
    }

    @Test("Examples tags included for outline expansion")
    func examplesTags() throws {
        let source = """
            @ftag
            Feature: Tags
              @otag
              Scenario Outline: S1
                Given <x>

                @etag
                Examples:
                  | x |
                  | 1 |
            """
        let doc = try parser.parse(source: source)
        let pickles = compiler.compile(doc)
        let tagNames = pickles[0].tags.map(\.name)
        #expect(tagNames.contains("@ftag"))
        #expect(tagNames.contains("@otag"))
        #expect(tagNames.contains("@etag"))
        #expect(tagNames.count == 3)
    }

    @Test("Full tag chain: feature → rule → scenario → examples")
    func fullTagChain() throws {
        let source = """
            @f
            Feature: Tags
              @r
              Rule: R1
                @s
                Scenario Outline: SO
                  Given <x>

                  @e
                  Examples:
                    | x |
                    | 1 |
            """
        let doc = try parser.parse(source: source)
        let pickles = compiler.compile(doc)
        let tagNames = pickles[0].tags.map(\.name)
        #expect(tagNames == ["@f", "@r", "@s", "@e"])
    }
}

@Suite("PickleCompiler — Scenario Outline Tests")
struct PickleCompilerOutlineTests {

    let compiler = PickleCompiler()
    let parser = GherkinParser()

    @Test("Outline expands to N pickles")
    func outlineExpansion() throws {
        let source = """
            Feature: Outline
              Scenario Outline: Eating
                Given there are <start> cucumbers
                When I eat <eat> cucumbers
                Then I should have <left> cucumbers

                Examples:
                  | start | eat | left |
                  |    12 |   5 |    7 |
                  |    20 |   5 |   15 |
            """
        let doc = try parser.parse(source: source)
        let pickles = compiler.compile(doc)
        #expect(pickles.count == 2)
        #expect(pickles[0].steps[0].text == "there are 12 cucumbers")
        #expect(pickles[0].steps[1].text == "I eat 5 cucumbers")
        #expect(pickles[0].steps[2].text == "I should have 7 cucumbers")
        #expect(pickles[1].steps[0].text == "there are 20 cucumbers")
    }

    @Test("Outline name has placeholders substituted")
    func outlineNameSubstitution() throws {
        let source = """
            Feature: Names
              Scenario Outline: Login as <user>
                Given user <user>

                Examples:
                  | user  |
                  | alice |
                  | bob   |
            """
        let doc = try parser.parse(source: source)
        let pickles = compiler.compile(doc)
        #expect(pickles[0].name == "Login as alice")
        #expect(pickles[1].name == "Login as bob")
    }

    @Test("Multiple examples blocks produce combined pickles")
    func multipleExamplesBlocks() throws {
        let source = """
            Feature: Multi
              Scenario Outline: Test <x>
                Given <x>

                Examples: First
                  | x |
                  | a |
                  | b |

                Examples: Second
                  | x |
                  | c |
            """
        let doc = try parser.parse(source: source)
        let pickles = compiler.compile(doc)
        #expect(pickles.count == 3)
        #expect(pickles[0].steps[0].text == "a")
        #expect(pickles[1].steps[0].text == "b")
        #expect(pickles[2].steps[0].text == "c")
    }

    @Test("Outline with background includes background steps")
    func outlineWithBackground() throws {
        let source = """
            Feature: BG Outline
              Background:
                Given setup

              Scenario Outline: SO
                Given <x>

                Examples:
                  | x |
                  | 1 |
                  | 2 |
            """
        let doc = try parser.parse(source: source)
        let pickles = compiler.compile(doc)
        #expect(pickles.count == 2)
        #expect(pickles[0].steps.count == 2)
        #expect(pickles[0].steps[0].text == "setup")
        #expect(pickles[0].steps[1].text == "1")
    }

    @Test("Outline with no examples produces no pickles")
    func outlineNoExamples() throws {
        let source = """
            Feature: Empty
              Scenario Outline: SO
                Given <x>
            """
        let doc = try parser.parse(source: source)
        let pickles = compiler.compile(doc)
        #expect(pickles.isEmpty)
    }

    @Test("Outline with empty examples table produces no pickles")
    func outlineEmptyExamples() throws {
        let source = """
            Feature: Empty
              Scenario Outline: SO
                Given <x>

                Examples:
                  | x |
            """
        let doc = try parser.parse(source: source)
        let pickles = compiler.compile(doc)
        #expect(pickles.isEmpty)
    }

    @Test("Placeholder substitution in doc strings")
    func docStringSubstitution() throws {
        let source = """
            Feature: DocString
              Scenario Outline: DS
                Given the following:
                  \"\"\"
                  Hello <name>!
                  \"\"\"

                Examples:
                  | name  |
                  | Alice |
            """
        let doc = try parser.parse(source: source)
        let pickles = compiler.compile(doc)
        #expect(pickles.count == 1)
        let arg = pickles[0].steps[0].argument
        if case .docString(let ds) = arg {
            #expect(ds.content == "Hello Alice!")
        } else {
            Issue.record("Expected doc string argument")
        }
    }

    @Test("Placeholder substitution in data table cells")
    func dataTableSubstitution() throws {
        let source = """
            Feature: DataTable
              Scenario Outline: DT
                Given the users:
                  | name   |
                  | <name> |

                Examples:
                  | name  |
                  | Alice |
                  | Bob   |
            """
        let doc = try parser.parse(source: source)
        let pickles = compiler.compile(doc)
        #expect(pickles.count == 2)
        if case .dataTable(let dt) = pickles[0].steps[0].argument {
            #expect(dt.rows[1].cells[0].value == "Alice")
        } else {
            Issue.record("Expected data table argument")
        }
        if case .dataTable(let dt) = pickles[1].steps[0].argument {
            #expect(dt.rows[1].cells[0].value == "Bob")
        } else {
            Issue.record("Expected data table argument")
        }
    }

    @Test("Unmatched placeholder left as-is")
    func unmatchedPlaceholder() throws {
        let source = """
            Feature: Unmatched
              Scenario Outline: Test
                Given <missing> and <present>

                Examples:
                  | present |
                  | value   |
            """
        let doc = try parser.parse(source: source)
        let pickles = compiler.compile(doc)
        #expect(pickles[0].steps[0].text == "<missing> and value")
    }
}
