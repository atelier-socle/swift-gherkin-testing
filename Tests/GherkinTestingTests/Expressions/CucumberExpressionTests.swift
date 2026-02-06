// CucumberExpressionTests.swift
// GherkinTestingTests
//
// Copyright © 2026 Atelier Socle. MIT License.

import Testing

@testable import GherkinTesting

@Suite("CucumberExpression")
struct CucumberExpressionTests {

    // MARK: - Basic Parameter Types

    @Test("matches {int} parameter")
    func matchInt() throws {
        let expr = try CucumberExpression("I have {int} cucumbers")
        let match = try #require(try expr.match("I have 42 cucumbers"))
        #expect(match.rawArguments == ["42"])
        #expect(match.paramTypeNames == ["int"])
    }

    @Test("matches negative {int}")
    func matchNegativeInt() throws {
        let expr = try CucumberExpression("the balance is {int}")
        let match = try #require(try expr.match("the balance is -100"))
        #expect(match.rawArguments == ["-100"])
    }

    @Test("matches {float} parameter")
    func matchFloat() throws {
        let expr = try CucumberExpression("the price is {float}")
        let match = try #require(try expr.match("the price is 3.14"))
        #expect(match.rawArguments == ["3.14"])
        #expect(match.paramTypeNames == ["float"])
    }

    @Test("matches negative {float}")
    func matchNegativeFloat() throws {
        let expr = try CucumberExpression("the temperature is {float}")
        let match = try #require(try expr.match("the temperature is -2.5"))
        #expect(match.rawArguments == ["-2.5"])
    }

    @Test("matches {float} without leading digit")
    func matchFloatNoLeadingDigit() throws {
        let expr = try CucumberExpression("the value is {float}")
        let match = try #require(try expr.match("the value is .5"))
        #expect(match.rawArguments == [".5"])
    }

    @Test("matches {string} with double quotes")
    func matchStringDoubleQuotes() throws {
        let expr = try CucumberExpression("the user enters {string}")
        let match = try #require(try expr.match("the user enters \"hello world\""))
        #expect(match.rawArguments == ["hello world"])
    }

    @Test("matches {string} with single quotes")
    func matchStringSingleQuotes() throws {
        let expr = try CucumberExpression("the user enters {string}")
        let match = try #require(try expr.match("the user enters 'hello world'"))
        #expect(match.rawArguments == ["hello world"])
    }

    @Test("matches {word} parameter")
    func matchWord() throws {
        let expr = try CucumberExpression("I click the {word} button")
        let match = try #require(try expr.match("I click the submit button"))
        #expect(match.rawArguments == ["submit"])
    }

    @Test("matches anonymous {} parameter")
    func matchAnonymous() throws {
        let expr = try CucumberExpression("I see {}")
        let match = try #require(try expr.match("I see something here"))
        #expect(match.rawArguments == ["something here"])
    }

    // MARK: - Multiple Parameters

    @Test("matches multiple {int} parameters")
    func multipleInts() throws {
        let expr = try CucumberExpression("I have {int} cats and {int} dogs")
        let match = try #require(try expr.match("I have 3 cats and 5 dogs"))
        #expect(match.rawArguments == ["3", "5"])
        #expect(match.paramTypeNames == ["int", "int"])
    }

    @Test("matches mixed parameter types")
    func mixedParams() throws {
        let expr = try CucumberExpression("{string} has {int} items at {float}")
        let match = try #require(try expr.match("\"Alice\" has 5 items at 9.99"))
        #expect(match.rawArguments == ["Alice", "5", "9.99"])
        #expect(match.paramTypeNames == ["string", "int", "float"])
    }

    @Test("matches {word} and {string} together")
    func wordAndString() throws {
        let expr = try CucumberExpression("the {word} user sees {string}")
        let match = try #require(try expr.match("the admin user sees \"dashboard\""))
        #expect(match.rawArguments == ["admin", "dashboard"])
    }

    // MARK: - Optional Text

    @Test("matches optional text present")
    func optionalPresent() throws {
        let expr = try CucumberExpression("I have {int} cucumber(s)")
        let match = try #require(try expr.match("I have 5 cucumbers"))
        #expect(match.rawArguments == ["5"])
    }

    @Test("matches optional text absent")
    func optionalAbsent() throws {
        let expr = try CucumberExpression("I have {int} cucumber(s)")
        let match = try #require(try expr.match("I have 1 cucumber"))
        #expect(match.rawArguments == ["1"])
    }

    @Test("matches multiple optional groups")
    func multipleOptional() throws {
        let expr = try CucumberExpression("I (really )like cucumber(s)")
        let match1 = try expr.match("I like cucumber")
        #expect(match1 != nil)
        let match2 = try expr.match("I really like cucumbers")
        #expect(match2 != nil)
    }

    // MARK: - Alternation

    @Test("matches first alternative")
    func alternationFirst() throws {
        let expr = try CucumberExpression("I eat/drink a {word}")
        let match = try #require(try expr.match("I eat a pizza"))
        #expect(match.rawArguments == ["pizza"])
    }

    @Test("matches second alternative")
    func alternationSecond() throws {
        let expr = try CucumberExpression("I eat/drink a {word}")
        let match = try #require(try expr.match("I drink a coffee"))
        #expect(match.rawArguments == ["coffee"])
    }

    @Test("alternation with multiple words")
    func alternationMultiWord() throws {
        let expr = try CucumberExpression("the color/colour is {word}")
        let match1 = try #require(try expr.match("the color is red"))
        #expect(match1.rawArguments == ["red"])
        let match2 = try #require(try expr.match("the colour is blue"))
        #expect(match2.rawArguments == ["blue"])
    }

    // MARK: - Escaping

    @Test("escaped opening brace is literal")
    func escapedBrace() throws {
        let expr = try CucumberExpression(#"I see \{text\}"#)
        let match = try expr.match("I see {text}")
        #expect(match != nil)
    }

    @Test("escaped opening paren is literal")
    func escapedParen() throws {
        let expr = try CucumberExpression(#"I see \(text\)"#)
        let match = try expr.match("I see (text)")
        #expect(match != nil)
    }

    @Test("escaped slash is literal")
    func escapedSlash() throws {
        let expr = try CucumberExpression(#"a\/b"#)
        let match = try expr.match("a/b")
        #expect(match != nil)
        let noMatch = try expr.match("a")
        #expect(noMatch == nil)
    }

    @Test("escaped backslash is literal")
    func escapedBackslash() throws {
        let expr = try CucumberExpression(#"path\\to"#)
        let match = try expr.match(#"path\to"#)
        #expect(match != nil)
    }

    // MARK: - No Match

    @Test("returns nil when text does not match")
    func noMatch() throws {
        let expr = try CucumberExpression("I have {int} cucumbers")
        let match = try expr.match("I have some cucumbers")
        #expect(match == nil)
    }

    @Test("does not match partial text")
    func noPartialMatch() throws {
        let expr = try CucumberExpression("hello")
        let match = try expr.match("hello world")
        #expect(match == nil)
    }

    @Test("does not match prefix missing")
    func noPrefixMatch() throws {
        let expr = try CucumberExpression("hello")
        let match = try expr.match("say hello")
        #expect(match == nil)
    }

    // MARK: - Expression Without Parameters

    @Test("expression without parameters matches exact text")
    func noParams() throws {
        let expr = try CucumberExpression("the user is logged in")
        let match = try expr.match("the user is logged in")
        #expect(match != nil)
        #expect(match?.rawArguments.isEmpty == true)
        #expect(match?.paramTypeNames.isEmpty == true)
    }

    @Test("parameterCount returns correct count")
    func parameterCount() throws {
        let expr0 = try CucumberExpression("hello")
        #expect(expr0.parameterCount == 0)

        let expr1 = try CucumberExpression("I have {int}")
        #expect(expr1.parameterCount == 1)

        let expr3 = try CucumberExpression("{string} buys {int} at {float}")
        #expect(expr3.parameterCount == 3)
    }

    // MARK: - Custom Parameter Types

    @Test("matches custom parameter type")
    func customParameterType() throws {
        var registry = ParameterTypeRegistry()
        let colorType = ParameterType<String>(
            name: "color",
            regexps: ["red|green|blue"],
            type: String.self,
            converter: { $0 }
        )
        try registry.register(colorType)

        let expr = try CucumberExpression("the {color} button", registry: registry)
        let match = try #require(try expr.match("the red button"))
        #expect(match.rawArguments == ["red"])
        #expect(match.paramTypeNames == ["color"])
    }

    @Test("unknown parameter type throws error")
    func unknownParameterType() throws {
        #expect(throws: ExpressionError.self) {
            _ = try CucumberExpression("the {color} button")
        }
    }

    // MARK: - Pattern Compilation

    @Test("source is preserved")
    func sourcePreserved() throws {
        let expr = try CucumberExpression("I have {int} cucumber(s)")
        #expect(expr.source == "I have {int} cucumber(s)")
    }

    @Test("pattern is anchored")
    func patternAnchored() throws {
        let expr = try CucumberExpression("hello {word}")
        #expect(expr.pattern.hasPrefix("^"))
        #expect(expr.pattern.hasSuffix("$"))
    }
}

// MARK: - Combinations & Typed Arguments

extension CucumberExpressionTests {

    @Test("optional + alternation + parameter combined")
    func combinedFeatures() throws {
        let expr = try CucumberExpression("I (quickly )eat/drink {int} item(s)")
        let m1 = try expr.match("I eat 1 item")
        #expect(m1 != nil)
        #expect(m1?.rawArguments == ["1"])

        let m2 = try expr.match("I quickly drink 5 items")
        #expect(m2 != nil)
        #expect(m2?.rawArguments == ["5"])
    }

    @Test("literal text with special regex chars")
    func specialChars() throws {
        let expr = try CucumberExpression("the price is ${float}")
        let match = try #require(try expr.match("the price is $9.99"))
        #expect(match.rawArguments == ["9.99"])
    }

    @Test("expression with dots in literal text")
    func dotsInText() throws {
        let expr = try CucumberExpression("version {word} is released")
        let match = try #require(try expr.match("version 2.0.1 is released"))
        #expect(match.rawArguments == ["2.0.1"])
    }

    @Test("{int} produces typed Int value")
    func typedInt() throws {
        let expr = try CucumberExpression("I have {int} cucumbers")
        let match = try #require(try expr.match("I have -42 cucumbers"))
        #expect(match.rawArguments == ["-42"])
        let typed = match.typedArguments[0]
        #expect(typed is Int)
        #expect(typed as? Int == -42)
    }

    @Test("{float} produces typed Double value")
    func typedFloat() throws {
        let expr = try CucumberExpression("the price is {float}")
        let match = try #require(try expr.match("the price is 3.14"))
        #expect(match.rawArguments == ["3.14"])
        let typed = match.typedArguments[0]
        #expect(typed is Double)
        #expect(typed as? Double == 3.14)
    }

    @Test("{float} with negative value produces typed Double")
    func typedNegativeFloat() throws {
        let expr = try CucumberExpression("the temperature is {float}")
        let match = try #require(try expr.match("the temperature is -2.5"))
        let typed = match.typedArguments[0]
        #expect(typed is Double)
        #expect(typed as? Double == -2.5)
    }

    @Test("{string} produces typed String with quotes stripped")
    func typedString() throws {
        let expr = try CucumberExpression("the user enters {string}")
        let match = try #require(try expr.match("the user enters \"hello world\""))
        #expect(match.rawArguments == ["hello world"])
        let typed = match.typedArguments[0]
        #expect(typed is String)
        #expect(typed as? String == "hello world")
    }

    @Test("{word} produces typed String")
    func typedWord() throws {
        let expr = try CucumberExpression("I click the {word} button")
        let match = try #require(try expr.match("I click the submit button"))
        let typed = match.typedArguments[0]
        #expect(typed is String)
        #expect(typed as? String == "submit")
    }

    @Test("mixed typed arguments preserve types")
    func typedMixed() throws {
        let expr = try CucumberExpression("{string} has {int} items at {float}")
        let match = try #require(try expr.match("\"Alice\" has 5 items at 9.99"))
        #expect(match.typedArguments.count == 3)
        #expect(match.typedArguments[0] is String)
        #expect(match.typedArguments[0] as? String == "Alice")
        #expect(match.typedArguments[1] is Int)
        #expect(match.typedArguments[1] as? Int == 5)
        #expect(match.typedArguments[2] is Double)
        #expect(match.typedArguments[2] as? Double == 9.99)
    }

    @Test("custom parameter type produces correct typed value")
    func typedCustom() throws {
        var registry = ParameterTypeRegistry()
        let colorType = ParameterType<Int>(
            name: "color",
            regexps: ["red|green|blue"],
            type: Int.self,
            converter: { raw in
                switch raw {
                case "red": return 0
                case "green": return 1
                case "blue": return 2
                default: return -1
                }
            }
        )
        try registry.register(colorType)

        let expr = try CucumberExpression("the {color} button", registry: registry)
        let match = try #require(try expr.match("the red button"))
        #expect(match.rawArguments == ["red"])
        let typed = match.typedArguments[0]
        #expect(typed is Int)
        #expect(typed as? Int == 0)
    }

    @Test("typedArguments count matches rawArguments count")
    func typedCountMatchesRaw() throws {
        let expr = try CucumberExpression("I have {int} cats and {int} dogs")
        let match = try #require(try expr.match("I have 3 cats and 5 dogs"))
        #expect(match.typedArguments.count == match.rawArguments.count)
        #expect(match.typedArguments[0] as? Int == 3)
        #expect(match.typedArguments[1] as? Int == 5)
    }

    @Test("expression without parameters has empty typedArguments")
    func typedEmpty() throws {
        let expr = try CucumberExpression("the user is logged in")
        let match = try #require(try expr.match("the user is logged in"))
        #expect(match.typedArguments.isEmpty)
    }
}
