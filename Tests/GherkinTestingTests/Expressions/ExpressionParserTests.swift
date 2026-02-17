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

@Suite("ExpressionParser")
struct ExpressionParserTests {

    private func parser() -> ExpressionParser {
        ExpressionParser(registry: ParameterTypeRegistry())
    }

    // MARK: - Tokenization

    @Test("tokenizes plain text")
    func tokenizePlainText() throws {
        let tokens = try parser().tokenize("hello world")
        #expect(tokens == [.text("hello world")])
    }

    @Test("tokenizes parameter placeholder")
    func tokenizeParameter() throws {
        let tokens = try parser().tokenize("I have {int} items")
        #expect(tokens == [.text("I have "), .parameter("int"), .text(" items")])
    }

    @Test("tokenizes anonymous parameter")
    func tokenizeAnonymousParam() throws {
        let tokens = try parser().tokenize("I see {}")
        #expect(tokens == [.text("I see "), .parameter("")])
    }

    @Test("tokenizes optional text")
    func tokenizeOptional() throws {
        let tokens = try parser().tokenize("cucumber(s)")
        #expect(tokens == [.text("cucumber"), .optional("s")])
    }

    @Test("tokenizes alternation")
    func tokenizeAlternation() throws {
        let tokens = try parser().tokenize("color/colour")
        #expect(tokens == [.alternation(["color", "colour"])])
    }

    @Test("tokenizes escaped brace")
    func tokenizeEscapedBrace() throws {
        let tokens = try parser().tokenize(#"I see \{text\}"#)
        #expect(tokens == [.text("I see {text}")])
    }

    @Test("tokenizes escaped paren")
    func tokenizeEscapedParen() throws {
        let tokens = try parser().tokenize(#"I see \(text\)"#)
        #expect(tokens == [.text("I see (text)")])
    }

    @Test("tokenizes escaped slash")
    func tokenizeEscapedSlash() throws {
        let tokens = try parser().tokenize(#"a\/b"#)
        #expect(tokens == [.text("a/b")])
    }

    @Test("tokenizes mixed expression")
    func tokenizeMixed() throws {
        let tokens = try parser().tokenize("I have {int} cucumber(s)")
        #expect(
            tokens == [
                .text("I have "),
                .parameter("int"),
                .text(" cucumber"),
                .optional("s")
            ])
    }

    @Test("tokenizes alternation adjacent to parameter")
    func tokenizeAlternationWithParam() throws {
        let tokens = try parser().tokenize("I eat/drink a {word}")
        #expect(
            tokens == [
                .text("I "),
                .alternation(["eat", "drink"]),
                .text(" a "),
                .parameter("word")
            ])
    }

    @Test("tokenizes multiple alternation parts")
    func tokenizeThreeAlternation() throws {
        let tokens = try parser().tokenize("red/green/blue")
        #expect(tokens == [.alternation(["red", "green", "blue"])])
    }

    // MARK: - Compilation

    @Test("compiles plain text to anchored regex")
    func compilePlainText() throws {
        let (pattern, types) = try parser().compile("hello world")
        #expect(pattern == "^hello world$")
        #expect(types.isEmpty)
    }

    @Test("compiles {int} to regex capture group")
    func compileInt() throws {
        let (pattern, types) = try parser().compile("I have {int} items")
        #expect(pattern == #"^I have (-?\d+) items$"#)
        #expect(types == ["int"])
    }

    @Test("compiles {float} to regex capture group")
    func compileFloat() throws {
        let (pattern, types) = try parser().compile("price is {float}")
        #expect(pattern == #"^price is (-?\d*\.\d+)$"#)
        #expect(types == ["float"])
    }

    @Test("compiles {string} to regex with alternation")
    func compileString() throws {
        let (pattern, types) = try parser().compile("enter {string}")
        #expect(pattern == #"^enter ("[^"]*"|'[^']*')$"#)
        #expect(types == ["string"])
    }

    @Test("compiles {word} to regex")
    func compileWord() throws {
        let (pattern, types) = try parser().compile("the {word} button")
        #expect(pattern == #"^the ([^\s]+) button$"#)
        #expect(types == ["word"])
    }

    @Test("compiles {} to regex")
    func compileAnonymous() throws {
        let (pattern, types) = try parser().compile("I see {}")
        #expect(pattern == "^I see (.+)$")
        #expect(types == [""])
    }

    @Test("compiles optional text")
    func compileOptional() throws {
        let (pattern, _) = try parser().compile("cucumber(s)")
        #expect(pattern == "^cucumber(?:s)?$")
    }

    @Test("compiles alternation without surrounding text")
    func compileAlternation() throws {
        let (pattern, _) = try parser().compile("color/colour")
        #expect(pattern == "^(?:color|colour)$")
    }

    @Test("compiles alternation with surrounding text")
    func compileAlternationWithContext() throws {
        let (pattern, _) = try parser().compile("I eat/drink a meal")
        #expect(pattern == "^I (?:eat|drink) a meal$")
    }

    @Test("escapes regex metacharacters in text")
    func escapesMetachars() throws {
        let (pattern, _) = try parser().compile("price is $5.00")
        #expect(pattern == #"^price is \$5\.00$"#)
    }

    @Test("compiles multiple parameters")
    func compileMultipleParams() throws {
        let (_, types) = try parser().compile("{string} buys {int} at {float}")
        #expect(types == ["string", "int", "float"])
    }

    // MARK: - Error Cases

    @Test("unterminated parameter throws error")
    func unterminatedParameter() throws {
        #expect(throws: ExpressionError.self) {
            _ = try parser().tokenize("I have {int items")
        }
    }

    @Test("unterminated optional throws error")
    func unterminatedOptional() throws {
        #expect(throws: ExpressionError.self) {
            _ = try parser().tokenize("cucumber(s")
        }
    }

    @Test("unknown parameter type throws error on compile")
    func unknownParamType() throws {
        #expect(throws: ExpressionError.self) {
            _ = try parser().compile("the {color} button")
        }
    }

    @Test("parameter in optional throws error")
    func paramInOptional() throws {
        #expect(throws: ExpressionError.self) {
            _ = try parser().tokenize("I have ({int}) items")
        }
    }

    // MARK: - Custom Parameter Types

    @Test("compiles with custom parameter type")
    func compileCustomType() throws {
        var registry = ParameterTypeRegistry()
        try registry.registerAny(
            AnyParameterType(
                name: "color",
                regexps: ["red|green|blue"],
                transformer: { $0 }
            ))
        let customParser = ExpressionParser(registry: registry)
        let (pattern, types) = try customParser.compile("the {color} button")
        #expect(pattern == "^the (red|green|blue) button$")
        #expect(types == ["color"])
    }

    // MARK: - Additional Edge Cases

    @Test("tokenizes escaped backslash")
    func tokenizeEscapedBackslash() throws {
        let tokens = try parser().tokenize(#"path\\to"#)
        #expect(tokens == [.text(#"path\to"#)])
    }

    @Test("multiple parameters in one expression")
    func compileThreeParams() throws {
        let (pattern, types) = try parser().compile("{int} plus {int} equals {int}")
        #expect(types == ["int", "int", "int"])
        #expect(pattern.hasPrefix("^"))
        #expect(pattern.hasSuffix("$"))
    }

    @Test("compiles parameter with multiple regex alternatives")
    func compileMultiRegexParam() throws {
        var registry = ParameterTypeRegistry()
        try registry.registerAny(
            AnyParameterType(
                name: "quoted",
                regexps: [#""[^"]*""#, #"'[^']*'"#],
                transformer: { $0 }
            ))
        let customParser = ExpressionParser(registry: registry)
        let (pattern, _) = try customParser.compile("I see {quoted}")
        #expect(pattern.contains("|"))
    }

    // MARK: - ExpressionError Descriptions

    @Test("ExpressionError.unterminatedParameter description")
    func unterminatedParamDesc() {
        let error = ExpressionError.unterminatedParameter("I have {int")
        #expect(error.errorDescription?.contains("Unterminated parameter") == true)
    }

    @Test("ExpressionError.unterminatedOptional description")
    func unterminatedOptionalDesc() {
        let error = ExpressionError.unterminatedOptional("word(s")
        #expect(error.errorDescription?.contains("Unterminated optional") == true)
    }

    @Test("ExpressionError.unknownParameterType description")
    func unknownParamTypeDesc() {
        let error = ExpressionError.unknownParameterType("color")
        #expect(error.errorDescription?.contains("color") == true)
    }

    @Test("ExpressionError.emptyExpression description")
    func emptyExpressionDesc() {
        let error = ExpressionError.emptyExpression
        #expect(error.errorDescription?.contains("empty") == true)
    }

    @Test("ExpressionError.emptyAlternative description")
    func emptyAlternativeDesc() {
        let error = ExpressionError.emptyAlternative("a//b")
        #expect(error.errorDescription?.contains("Empty alternative") == true)
    }

    @Test("ExpressionError.parameterInAlternation description")
    func paramInAlternationDesc() {
        let error = ExpressionError.parameterInAlternation("a/{int}")
        #expect(error.errorDescription?.contains("not allowed in alternation") == true)
    }

    @Test("ExpressionError.parameterInOptional description")
    func paramInOptionalDesc() {
        let error = ExpressionError.parameterInOptional("({int})")
        #expect(error.errorDescription?.contains("not allowed in optional") == true)
    }

    // MARK: - Alternation Boundary Extraction

    @Test("alternation without spaces stays intact")
    func alternationNoSpaces() throws {
        let tokens = try parser().tokenize("red/green/blue")
        #expect(tokens == [.alternation(["red", "green", "blue"])])
    }

    @Test("alternation with prefix text")
    func alternationWithPrefix() throws {
        let tokens = try parser().tokenize("I run/walk fast")
        #expect(
            tokens == [
                .text("I "),
                .alternation(["run", "walk"]),
                .text(" fast")
            ])
    }
}
