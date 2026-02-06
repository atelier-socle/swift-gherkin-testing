// TagFilterTests.swift
// GherkinTestingTests
//
// Copyright © 2026 Atelier Socle. MIT License.

import Testing
@testable import GherkinTesting

@Suite("TagFilter")
struct TagFilterTests {

    // MARK: - Simple Tag

    @Test("matches a single tag")
    func simpleTagMatch() throws {
        let filter = try TagFilter("@smoke")
        #expect(filter.matches(tags: ["@smoke"]))
        #expect(filter.matches(tags: ["@smoke", "@login"]))
    }

    @Test("does not match when tag is absent")
    func simpleTagNoMatch() throws {
        let filter = try TagFilter("@smoke")
        #expect(!filter.matches(tags: []))
        #expect(!filter.matches(tags: ["@login"]))
    }

    // MARK: - Not

    @Test("not negates a tag")
    func notTag() throws {
        let filter = try TagFilter("not @wip")
        #expect(filter.matches(tags: []))
        #expect(filter.matches(tags: ["@smoke"]))
        #expect(!filter.matches(tags: ["@wip"]))
        #expect(!filter.matches(tags: ["@smoke", "@wip"]))
    }

    @Test("double not cancels out")
    func doubleNot() throws {
        let filter = try TagFilter("not not @smoke")
        #expect(filter.matches(tags: ["@smoke"]))
        #expect(!filter.matches(tags: []))
    }

    // MARK: - And

    @Test("and requires both tags")
    func andBothRequired() throws {
        let filter = try TagFilter("@smoke and @login")
        #expect(filter.matches(tags: ["@smoke", "@login"]))
        #expect(filter.matches(tags: ["@smoke", "@login", "@fast"]))
        #expect(!filter.matches(tags: ["@smoke"]))
        #expect(!filter.matches(tags: ["@login"]))
        #expect(!filter.matches(tags: []))
    }

    @Test("chained and requires all tags")
    func chainedAnd() throws {
        let filter = try TagFilter("@a and @b and @c")
        #expect(filter.matches(tags: ["@a", "@b", "@c"]))
        #expect(!filter.matches(tags: ["@a", "@b"]))
    }

    // MARK: - Or

    @Test("or requires either tag")
    func orEitherMatches() throws {
        let filter = try TagFilter("@smoke or @slow")
        #expect(filter.matches(tags: ["@smoke"]))
        #expect(filter.matches(tags: ["@slow"]))
        #expect(filter.matches(tags: ["@smoke", "@slow"]))
        #expect(!filter.matches(tags: []))
        #expect(!filter.matches(tags: ["@fast"]))
    }

    @Test("chained or requires any tag")
    func chainedOr() throws {
        let filter = try TagFilter("@a or @b or @c")
        #expect(filter.matches(tags: ["@a"]))
        #expect(filter.matches(tags: ["@b"]))
        #expect(filter.matches(tags: ["@c"]))
        #expect(!filter.matches(tags: []))
    }

    // MARK: - Parentheses

    @Test("parentheses group or with and")
    func parenthesesGrouping() throws {
        let filter = try TagFilter("(@smoke or @slow) and not @wip")
        #expect(filter.matches(tags: ["@smoke"]))
        #expect(filter.matches(tags: ["@slow"]))
        #expect(!filter.matches(tags: ["@smoke", "@wip"]))
        #expect(!filter.matches(tags: ["@wip"]))
        #expect(!filter.matches(tags: []))
    }

    @Test("nested parentheses")
    func nestedParentheses() throws {
        let filter = try TagFilter("((@a or @b) and @c)")
        #expect(filter.matches(tags: ["@a", "@c"]))
        #expect(filter.matches(tags: ["@b", "@c"]))
        #expect(!filter.matches(tags: ["@a"]))
        #expect(!filter.matches(tags: ["@c"]))
    }

    // MARK: - Operator Precedence

    @Test("not binds tighter than and")
    func notPrecedenceOverAnd() throws {
        // "not @a and @b" → "(not @a) and @b"
        let filter = try TagFilter("not @a and @b")
        #expect(filter.matches(tags: ["@b"]))
        #expect(!filter.matches(tags: ["@a", "@b"]))
        #expect(!filter.matches(tags: ["@a"]))
        #expect(!filter.matches(tags: []))
    }

    @Test("and binds tighter than or")
    func andPrecedenceOverOr() throws {
        // "@a or @b and @c" → "@a or (@b and @c)"
        let filter = try TagFilter("@a or @b and @c")
        #expect(filter.matches(tags: ["@a"]))
        #expect(filter.matches(tags: ["@b", "@c"]))
        #expect(!filter.matches(tags: ["@b"]))
        #expect(!filter.matches(tags: ["@c"]))
    }

    // MARK: - Combinations

    @Test("complex expression with all operators")
    func complexExpression() throws {
        let filter = try TagFilter("(@smoke or @regression) and not @wip and not @skip")
        #expect(filter.matches(tags: ["@smoke"]))
        #expect(filter.matches(tags: ["@regression"]))
        #expect(!filter.matches(tags: ["@smoke", "@wip"]))
        #expect(!filter.matches(tags: ["@smoke", "@skip"]))
        #expect(!filter.matches(tags: ["@fast"]))
    }

    @Test("not or combination")
    func notOrCombination() throws {
        let filter = try TagFilter("not (@slow or @wip)")
        #expect(filter.matches(tags: []))
        #expect(filter.matches(tags: ["@smoke"]))
        #expect(!filter.matches(tags: ["@slow"]))
        #expect(!filter.matches(tags: ["@wip"]))
        #expect(!filter.matches(tags: ["@slow", "@wip"]))
    }

    // MARK: - Error Handling

    @Test("empty expression throws error")
    func emptyExpression() {
        #expect(throws: TagFilterError.emptyExpression) {
            try TagFilter("")
        }
    }

    @Test("whitespace-only expression throws error")
    func whitespaceOnlyExpression() {
        #expect(throws: TagFilterError.emptyExpression) {
            try TagFilter("   ")
        }
    }

    @Test("unexpected token throws error")
    func unexpectedToken() {
        #expect(throws: TagFilterError.self) {
            try TagFilter("@a + @b")
        }
    }

    @Test("missing closing parenthesis throws error")
    func missingClosingParen() {
        #expect(throws: TagFilterError.missingClosingParenthesis) {
            try TagFilter("(@a and @b")
        }
    }

    @Test("unexpected end of expression throws error")
    func unexpectedEnd() {
        #expect(throws: TagFilterError.unexpectedEndOfExpression) {
            try TagFilter("not")
        }
    }

    @Test("trailing operator throws error")
    func trailingOperator() {
        #expect(throws: TagFilterError.unexpectedEndOfExpression) {
            try TagFilter("@a and")
        }
    }

    // MARK: - Equatable

    @Test("TagFilter is equatable")
    func equatable() throws {
        let filter1 = try TagFilter("@smoke and @login")
        let filter2 = try TagFilter("@smoke and @login")
        let filter3 = try TagFilter("@smoke or @login")
        #expect(filter1 == filter2)
        #expect(filter1 != filter3)
    }
}
