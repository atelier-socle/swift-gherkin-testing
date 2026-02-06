// TagFilter.swift
// GherkinTesting
//
// Copyright © 2026 Atelier Socle. MIT License.

import Foundation

/// An error that occurs when parsing a tag filter expression.
public enum TagFilterError: Error, Sendable, Equatable {
    /// The expression string is empty.
    case emptyExpression

    /// An unexpected token was encountered at the given position.
    case unexpectedToken(String, position: Int)

    /// The expression ended unexpectedly.
    case unexpectedEndOfExpression

    /// A closing parenthesis was expected but not found.
    case missingClosingParenthesis
}

extension TagFilterError: LocalizedError {
    /// A localized description of the tag filter error.
    public var errorDescription: String? {
        switch self {
        case .emptyExpression:
            return "Tag filter expression is empty."
        case .unexpectedToken(let token, let position):
            return "Unexpected token \"\(token)\" at position \(position)."
        case .unexpectedEndOfExpression:
            return "Tag filter expression ended unexpectedly."
        case .missingClosingParenthesis:
            return "Missing closing parenthesis in tag filter expression."
        }
    }
}

/// A parsed tag expression AST node.
indirect enum TagExpression: Sendable, Equatable {
    /// A single tag (e.g. `@smoke`).
    case tag(String)

    /// Logical negation of an expression.
    case not(TagExpression)

    /// Logical conjunction of two expressions.
    case and(TagExpression, TagExpression)

    /// Logical disjunction of two expressions.
    case or(TagExpression, TagExpression)

    /// Evaluates this expression against a set of tag names.
    ///
    /// - Parameter tags: The tag names to evaluate against (including `@` prefix).
    /// - Returns: `true` if the tags satisfy this expression.
    func evaluate(tags: [String]) -> Bool {
        switch self {
        case .tag(let name):
            return tags.contains(name)
        case .not(let expr):
            return !expr.evaluate(tags: tags)
        case .and(let lhs, let rhs):
            return lhs.evaluate(tags: tags) && rhs.evaluate(tags: tags)
        case .or(let lhs, let rhs):
            return lhs.evaluate(tags: tags) || rhs.evaluate(tags: tags)
        }
    }
}

/// Evaluates whether a set of tags matches a boolean tag expression.
///
/// Tag filter expressions support:
/// - Simple tags: `@smoke`
/// - Negation: `not @wip`
/// - Conjunction: `@smoke and @login`
/// - Disjunction: `@smoke or @slow`
/// - Parentheses: `(@smoke or @slow) and not @wip`
///
/// Operator precedence: `not` > `and` > `or`.
///
/// ```swift
/// let filter = try TagFilter("@smoke and not @wip")
/// filter.matches(tags: ["@smoke", "@login"]) // true
/// filter.matches(tags: ["@smoke", "@wip"])    // false
/// ```
public struct TagFilter: Sendable, Equatable {
    /// The parsed expression tree.
    let expression: TagExpression

    /// Creates a tag filter by parsing the given expression string.
    ///
    /// - Parameter expressionString: A boolean tag expression.
    /// - Throws: ``TagFilterError`` if the expression is malformed.
    public init(_ expressionString: String) throws {
        let tokens = try TagFilter.tokenize(expressionString)
        if tokens.isEmpty {
            throw TagFilterError.emptyExpression
        }
        var parser = TagExpressionParser(tokens: tokens)
        self.expression = try parser.parseOrExpression()
        if parser.position < parser.tokens.count {
            throw TagFilterError.unexpectedToken(
                parser.tokens[parser.position].value,
                position: parser.position
            )
        }
    }

    /// Evaluates whether the given tags satisfy this filter expression.
    ///
    /// - Parameter tags: The tag names to evaluate (including `@` prefix).
    /// - Returns: `true` if the tags match the expression.
    public func matches(tags: [String]) -> Bool {
        expression.evaluate(tags: tags)
    }
}

// MARK: - Tokenizer

/// A token in a tag filter expression.
enum TagToken: Sendable, Equatable {
    case tag(String)
    case not
    case and
    case or
    case leftParen
    case rightParen

    var value: String {
        switch self {
        case .tag(let name): return name
        case .not: return "not"
        case .and: return "and"
        case .or: return "or"
        case .leftParen: return "("
        case .rightParen: return ")"
        }
    }
}

extension TagFilter {
    /// Tokenizes a tag filter expression string.
    static func tokenize(_ input: String) throws -> [TagToken] {
        var tokens: [TagToken] = []
        var index = input.startIndex

        while index < input.endIndex {
            let char = input[index]

            // Skip whitespace
            if char.isWhitespace {
                index = input.index(after: index)
                continue
            }

            // Parentheses
            if char == "(" {
                tokens.append(.leftParen)
                index = input.index(after: index)
                continue
            }
            if char == ")" {
                tokens.append(.rightParen)
                index = input.index(after: index)
                continue
            }

            // Tag: starts with @
            if char == "@" {
                let start = index
                index = input.index(after: index)
                while index < input.endIndex,
                      !input[index].isWhitespace,
                      input[index] != "(" && input[index] != ")" {
                    index = input.index(after: index)
                }
                tokens.append(.tag(String(input[start..<index])))
                continue
            }

            // Word: could be "not", "and", "or"
            if char.isLetter {
                let start = index
                while index < input.endIndex, input[index].isLetter {
                    index = input.index(after: index)
                }
                let word = String(input[start..<index])
                switch word {
                case "not": tokens.append(.not)
                case "and": tokens.append(.and)
                case "or": tokens.append(.or)
                default:
                    let pos = input.distance(from: input.startIndex, to: start)
                    throw TagFilterError.unexpectedToken(word, position: pos)
                }
                continue
            }

            let pos = input.distance(from: input.startIndex, to: index)
            throw TagFilterError.unexpectedToken(String(char), position: pos)
        }

        return tokens
    }
}

// MARK: - Parser

/// Recursive descent parser for tag expressions.
///
/// Grammar (precedence: not > and > or):
/// ```
/// or_expr  = and_expr ("or" and_expr)*
/// and_expr = not_expr ("and" not_expr)*
/// not_expr = "not" not_expr | primary
/// primary  = "(" or_expr ")" | TAG
/// ```
struct TagExpressionParser {
    let tokens: [TagToken]
    var position: Int = 0

    mutating func parseOrExpression() throws -> TagExpression {
        var left = try parseAndExpression()
        while position < tokens.count, tokens[position] == .or {
            position += 1
            let right = try parseAndExpression()
            left = .or(left, right)
        }
        return left
    }

    mutating func parseAndExpression() throws -> TagExpression {
        var left = try parseNotExpression()
        while position < tokens.count, tokens[position] == .and {
            position += 1
            let right = try parseNotExpression()
            left = .and(left, right)
        }
        return left
    }

    mutating func parseNotExpression() throws -> TagExpression {
        if position < tokens.count, tokens[position] == .not {
            position += 1
            let operand = try parseNotExpression()
            return .not(operand)
        }
        return try parsePrimary()
    }

    mutating func parsePrimary() throws -> TagExpression {
        guard position < tokens.count else {
            throw TagFilterError.unexpectedEndOfExpression
        }

        switch tokens[position] {
        case .tag(let name):
            position += 1
            return .tag(name)
        case .leftParen:
            position += 1
            let expr = try parseOrExpression()
            guard position < tokens.count, tokens[position] == .rightParen else {
                throw TagFilterError.missingClosingParenthesis
            }
            position += 1
            return expr
        default:
            throw TagFilterError.unexpectedToken(tokens[position].value, position: position)
        }
    }
}
