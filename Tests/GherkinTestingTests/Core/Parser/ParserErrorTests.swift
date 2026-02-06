// ParserErrorTests.swift
// GherkinTestingTests
//
// Copyright © 2026 Atelier Socle. MIT License.

import Testing

@testable import GherkinTesting

@Suite("ParserError")
struct ParserErrorTests {

    // MARK: - Error Description

    @Test("errorDescription formats location and message")
    func errorDescription() {
        let error = ParserError(
            location: Location(line: 10, column: 5),
            message: "Something went wrong"
        )
        #expect(error.errorDescription == "(10:5): Something went wrong")
    }

    @Test("errorDescription with zero column")
    func errorDescriptionZeroColumn() {
        let error = ParserError(
            location: Location(line: 1, column: 0),
            message: "Issue at start"
        )
        #expect(error.errorDescription == "(1:0): Issue at start")
    }

    // MARK: - Factory Methods

    @Test("unexpectedToken creates error with token info")
    func unexpectedToken() {
        let token = Token(
            type: .step,
            location: Location(line: 3, column: 7),
            text: "Given something"
        )
        let error = ParserError.unexpectedToken(token, expected: "Scenario keyword")
        #expect(error.location == Location(line: 3, column: 7))
        #expect(error.message.contains("step"))
        #expect(error.message.contains("expected Scenario keyword"))
    }

    @Test("unexpectedEOF creates error with location")
    func unexpectedEOF() {
        let loc = Location(line: 50, column: 1)
        let error = ParserError.unexpectedEOF(at: loc, expected: "closing doc string")
        #expect(error.location == loc)
        #expect(error.message.contains("Unexpected end of file"))
        #expect(error.message.contains("closing doc string"))
    }

    @Test("inconsistentTableCellCount creates error")
    func inconsistentTableCellCount() {
        let loc = Location(line: 15, column: 3)
        let error = ParserError.inconsistentTableCellCount(at: loc)
        #expect(error.location == loc)
        #expect(error.message.contains("Inconsistent cell count"))
    }

    @Test("duplicateBackground creates error")
    func duplicateBackground() {
        let loc = Location(line: 20)
        let error = ParserError.duplicateBackground(at: loc)
        #expect(error.location == loc)
        #expect(error.message.contains("Only one Background"))
    }

    // MARK: - Equatable / Hashable

    @Test("ParserError is equatable")
    func equatable() {
        let e1 = ParserError(location: Location(line: 1), message: "test")
        let e2 = ParserError(location: Location(line: 1), message: "test")
        let e3 = ParserError(location: Location(line: 2), message: "test")
        #expect(e1 == e2)
        #expect(e1 != e3)
    }

    @Test("ParserError is hashable")
    func hashable() {
        let e1 = ParserError(location: Location(line: 1), message: "a")
        let e2 = ParserError(location: Location(line: 1), message: "a")
        let set: Set<ParserError> = [e1, e2]
        #expect(set.count == 1)
    }
}
