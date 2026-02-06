// FeatureExecutorTests.swift
// GherkinTestingTests
//
// Copyright © 2026 Atelier Socle. MIT License.

import Testing

@testable import GherkinTesting

/// A minimal feature type for testing FeatureExecutor helpers.
private struct StubFeature: GherkinFeature {}

@Suite("FeatureExecutor Tests")
struct FeatureExecutorTests {

    // MARK: - extractStepLine

    @Test("extractStepLine parses line and column from astNodeIds")
    func extractStepLineBasic() throws {
        let step = PickleStep(
            id: "1",
            text: "the user is logged in",
            argument: nil,
            astNodeIds: ["10:5"]
        )
        let result = FeatureExecutor<StubFeature>.extractStepLine(from: step)
        let loc = try #require(result)
        #expect(loc.line == 10)
        #expect(loc.column == 5)
    }

    @Test("extractStepLine returns nil for empty astNodeIds")
    func extractStepLineEmpty() {
        let step = PickleStep(
            id: "1",
            text: "some step",
            argument: nil,
            astNodeIds: []
        )
        #expect(FeatureExecutor<StubFeature>.extractStepLine(from: step) == nil)
    }

    @Test("extractStepLine returns nil for malformed nodeId")
    func extractStepLineMalformed() {
        let step = PickleStep(
            id: "1",
            text: "some step",
            argument: nil,
            astNodeIds: ["not-a-location"]
        )
        #expect(FeatureExecutor<StubFeature>.extractStepLine(from: step) == nil)
    }

    // MARK: - buildStepSourceLocation

    @Test("buildStepSourceLocation for .file() points to feature file and step line")
    func buildSourceLocationFile() throws {
        let step = PickleStep(
            id: "1",
            text: "the user clicks login",
            argument: nil,
            astNodeIds: ["7:5"]
        )
        let loc = FeatureExecutor<StubFeature>.buildStepSourceLocation(
            for: step,
            source: .file("login.feature"),
            callerFileID: "TestModule/MyTest.swift",
            callerFilePath: "/path/to/MyTest.swift",
            callerLine: 42,
            callerColumn: 9
        )
        // For .file() source, SourceLocation should point to the .feature file line
        #expect(loc.line == 7)
        #expect(loc.column == 5)
    }

    @Test("buildStepSourceLocation for .file() with absolute path preserves path in fileID")
    func buildSourceLocationFileAbsolute() throws {
        let step = PickleStep(
            id: "1",
            text: "the user clicks login",
            argument: nil,
            astNodeIds: ["3:5"]
        )
        let loc = FeatureExecutor<StubFeature>.buildStepSourceLocation(
            for: step,
            source: .file("/path/to/login.feature"),
            callerFileID: "TestModule/MyTest.swift",
            callerFilePath: "/path/to/MyTest.swift",
            callerLine: 42,
            callerColumn: 9
        )
        // Absolute paths already contain /, so fileID is the path itself
        #expect(loc.fileID == "/path/to/login.feature")
        #expect(loc.line == 3)
    }

    @Test("buildStepSourceLocation for .inline() uses caller location")
    func buildSourceLocationInline() {
        let step = PickleStep(
            id: "1",
            text: "the user clicks login",
            argument: nil,
            astNodeIds: ["7:5"]
        )
        let loc = FeatureExecutor<StubFeature>.buildStepSourceLocation(
            for: step,
            source: .inline("Feature: Test\n  Scenario: Test\n    Given the user clicks login"),
            callerFileID: "TestModule/MyTest.swift",
            callerFilePath: "/path/to/MyTest.swift",
            callerLine: 42,
            callerColumn: 9
        )
        // For .inline() source, SourceLocation should use caller's location
        #expect(loc.fileID == "TestModule/MyTest.swift")
        #expect(loc.line == 42)
        #expect(loc.column == 9)
    }

    @Test("buildStepSourceLocation for .file() falls back to caller when no astNodeIds")
    func buildSourceLocationFileFallback() {
        let step = PickleStep(
            id: "1",
            text: "some step",
            argument: nil,
            astNodeIds: []
        )
        let loc = FeatureExecutor<StubFeature>.buildStepSourceLocation(
            for: step,
            source: .file("test.feature"),
            callerFileID: "TestModule/MyTest.swift",
            callerFilePath: "/path/to/MyTest.swift",
            callerLine: 10,
            callerColumn: 1
        )
        // Falls back to caller location when no astNodeIds
        #expect(loc.fileID == "TestModule/MyTest.swift")
        #expect(loc.line == 10)
    }
}
