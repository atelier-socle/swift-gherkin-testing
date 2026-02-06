// ExpressionParserTests.swift
// GherkinTestingTests
//
// Copyright © 2026 Atelier Socle. MIT License.

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
}
