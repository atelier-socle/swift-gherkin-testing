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

import Foundation
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
        let caller = CallerLocation(
            fileID: "TestModule/MyTest.swift",
            filePath: "/path/to/MyTest.swift",
            line: 42,
            column: 9
        )
        let loc = FeatureExecutor<StubFeature>.buildStepSourceLocation(
            for: step,
            source: .file("login.feature"),
            caller: caller
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
        let caller = CallerLocation(
            fileID: "TestModule/MyTest.swift",
            filePath: "/path/to/MyTest.swift",
            line: 42,
            column: 9
        )
        let loc = FeatureExecutor<StubFeature>.buildStepSourceLocation(
            for: step,
            source: .file("/path/to/login.feature"),
            caller: caller
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
        let caller = CallerLocation(
            fileID: "TestModule/MyTest.swift",
            filePath: "/path/to/MyTest.swift",
            line: 42,
            column: 9
        )
        let loc = FeatureExecutor<StubFeature>.buildStepSourceLocation(
            for: step,
            source: .inline("Feature: Test\n  Scenario: Test\n    Given the user clicks login"),
            caller: caller
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
        let caller = CallerLocation(
            fileID: "TestModule/MyTest.swift",
            filePath: "/path/to/MyTest.swift",
            line: 10,
            column: 1
        )
        let loc = FeatureExecutor<StubFeature>.buildStepSourceLocation(
            for: step,
            source: .file("test.feature"),
            caller: caller
        )
        // Falls back to caller location when no astNodeIds
        #expect(loc.fileID == "TestModule/MyTest.swift")
        #expect(loc.line == 10)
    }

    // MARK: - FeatureExecutor.run()

    @Test("run with inline source parses and executes scenarios")
    func runInlineSource() async throws {
        let gherkin = """
            Feature: Test
              Scenario: First
                Given step one
            """
        let defs: [StepDefinition<StubFeature>] = [
            StepDefinition(
                keywordType: .context,
                pattern: .exact("step one"),
                sourceLocation: Location(line: 1),
                handler: { _, _, _ in }
            )
        ]
        let result = try await FeatureExecutor<StubFeature>.run(
            source: .inline(gherkin),
            definitions: defs,
            featureFactory: { StubFeature() }
        )
        #expect(result.featureResults.count == 1)
        #expect(result.featureResults[0].scenarioResults.count == 1)
    }

    @Test("run with scenario filter only runs matching scenario")
    func runWithScenarioFilter() async throws {
        let gherkin = """
            Feature: Multi
              Scenario: A
                Given step a
              Scenario: B
                Given step b
            """
        let defs: [StepDefinition<StubFeature>] = [
            StepDefinition(
                keywordType: .context,
                pattern: .exact("step a"),
                sourceLocation: Location(line: 1),
                handler: { _, _, _ in }
            ),
            StepDefinition(
                keywordType: .context,
                pattern: .exact("step b"),
                sourceLocation: Location(line: 2),
                handler: { _, _, _ in }
            )
        ]
        let result = try await FeatureExecutor<StubFeature>.run(
            source: .inline(gherkin),
            definitions: defs,
            scenarioFilter: "A",
            featureFactory: { StubFeature() }
        )
        #expect(result.featureResults[0].scenarioResults.count == 1)
        #expect(result.featureResults[0].scenarioResults[0].name == "A")
    }

    @Test("run with dryRun config returns result with suggestions")
    func runDryRun() async throws {
        let gherkin = """
            Feature: DryRun
              Scenario: Missing steps
                Given undefined step here
            """
        let config = GherkinConfiguration(dryRun: true)
        let result = try await FeatureExecutor<StubFeature>.run(
            source: .inline(gherkin),
            definitions: [],
            configuration: config,
            featureFactory: { StubFeature() }
        )
        #expect(!result.featureResults.isEmpty)
    }

    @Test("run with file source and non-existent file throws error")
    func runFileSourceNotFound() async throws {
        await #expect(throws: Error.self) {
            _ = try await FeatureExecutor<StubFeature>.run(
                source: .file("/nonexistent/path/to/feature.feature"),
                definitions: [],
                featureFactory: { StubFeature() }
            )
        }
    }

    @Test("buildStepSourceLocation for .file() without slash prefixes GherkinFeature/")
    func buildSourceLocationFileNoSlash() {
        let step = PickleStep(
            id: "1",
            text: "test",
            argument: nil,
            astNodeIds: ["5:3"]
        )
        let caller = CallerLocation(
            fileID: "Module/Test.swift",
            filePath: "/tmp/Test.swift",
            line: 1,
            column: 1
        )
        let loc = FeatureExecutor<StubFeature>.buildStepSourceLocation(
            for: step,
            source: .file("simple.feature"),
            caller: caller
        )
        #expect(loc.fileID == "GherkinFeature/simple.feature")
        #expect(loc.line == 5)
        #expect(loc.column == 3)
    }

    // MARK: - FeatureExecutionError

    @Test("FeatureExecutionError errorDescription formats failures")
    func featureExecutionErrorDescription() {
        let error = FeatureExecutionError(failures: ["Step A failed", "Step B undefined"])
        let desc = error.errorDescription
        #expect(desc?.contains("Feature execution failed") == true)
        #expect(desc?.contains("Step A failed") == true)
        #expect(desc?.contains("Step B undefined") == true)
    }

    @Test("FeatureExecutionError with empty failures")
    func featureExecutionErrorEmpty() {
        let error = FeatureExecutionError(failures: [])
        let desc = error.errorDescription
        #expect(desc?.contains("Feature execution failed") == true)
    }

    // MARK: - CallerLocation

    @Test("CallerLocation stores all fields")
    func callerLocationFields() {
        let loc = CallerLocation(
            fileID: "M/F.swift",
            filePath: "/path/F.swift",
            line: 42,
            column: 7
        )
        #expect(loc.fileID == "M/F.swift")
        #expect(loc.filePath == "/path/F.swift")
        #expect(loc.line == 42)
        #expect(loc.column == 7)
    }

    // MARK: - extractStepLine edge cases

    @Test("extractStepLine with non-numeric parts returns nil")
    func extractStepLineNonNumeric() {
        let step = PickleStep(
            id: "1",
            text: "test",
            argument: nil,
            astNodeIds: ["abc:def"]
        )
        #expect(FeatureExecutor<StubFeature>.extractStepLine(from: step) == nil)
    }

    @Test("extractStepLine with single part returns nil")
    func extractStepLineSinglePart() {
        let step = PickleStep(
            id: "1",
            text: "test",
            argument: nil,
            astNodeIds: ["42"]
        )
        #expect(FeatureExecutor<StubFeature>.extractStepLine(from: step) == nil)
    }

}

@Suite("FeatureExecutor — Issue Reporting & Edge Cases")
struct FeatureExecutorIssueTests {

    @Test("run with undefined steps in non-dryRun mode reports issues")
    func runUndefinedStepsNonDryRun() async throws {
        let gherkin = """
            Feature: Undef
              Scenario: Missing
                Given this step is undefined
            """
        await withKnownIssue {
            _ = try await FeatureExecutor<StubFeature>.run(
                source: .inline(gherkin),
                definitions: [],
                featureFactory: { StubFeature() }
            )
        }
    }

    @Test("run with ambiguous steps reports issues")
    func runAmbiguousSteps() async throws {
        let gherkin = """
            Feature: Ambig
              Scenario: Duplicate
                Given ambiguous step
            """
        let defs: [StepDefinition<StubFeature>] = [
            StepDefinition(
                keywordType: .context,
                pattern: .regex("ambiguous.*"),
                sourceLocation: Location(line: 1),
                handler: { _, _, _ in }
            ),
            StepDefinition(
                keywordType: .context,
                pattern: .regex("ambiguous step"),
                sourceLocation: Location(line: 2),
                handler: { _, _, _ in }
            )
        ]
        await withKnownIssue {
            _ = try await FeatureExecutor<StubFeature>.run(
                source: .inline(gherkin),
                definitions: defs,
                featureFactory: { StubFeature() }
            )
        }
    }

    @Test("run with failed step reports issue")
    func runFailedStep() async throws {
        let gherkin = """
            Feature: Fail
              Scenario: Error
                Given this step will fail
            """
        let defs: [StepDefinition<StubFeature>] = [
            StepDefinition(
                keywordType: .context,
                pattern: .exact("this step will fail"),
                sourceLocation: Location(line: 1),
                handler: { _, _, _ in throw StubError() }
            )
        ]
        await withKnownIssue {
            _ = try await FeatureExecutor<StubFeature>.run(
                source: .inline(gherkin),
                definitions: defs,
                featureFactory: { StubFeature() }
            )
        }
    }

    // MARK: - loadFile edge case

    @Test("run with file source and relative path not in bundle falls back to plain path")
    func runFileSourceRelativeNotInBundle() async throws {
        await #expect(throws: Error.self) {
            _ = try await FeatureExecutor<StubFeature>.run(
                source: .file("nonexistent-relative.feature"),
                definitions: [],
                bundle: Bundle.main,
                featureFactory: { StubFeature() }
            )
        }
    }
}

// MARK: - ReportFormat auto-write

@Suite("FeatureExecutor — Report Auto-Write")
struct FeatureExecutorReportTests {

    private static let passingDefs: [StepDefinition<StubFeature>] = [
        StepDefinition(
            keywordType: .context,
            pattern: .exact("passing step"),
            sourceLocation: Location(line: 1),
            handler: { _, _, _ in }
        )
    ]

    private static let gherkin = """
        Feature: ReportTest
          Scenario: OK
            Given passing step
        """

    @Test("reports: [.html] writes HTML file with custom path")
    func reportsAutoWriteHTML() async throws {
        let dir = "/tmp/swift-gherkin-testing/test-html"
        let path = "\(dir)/report.html"
        try? FileManager.default.removeItem(atPath: dir)

        _ = try await FeatureExecutor<StubFeature>.run(
            source: .inline(Self.gherkin),
            definitions: Self.passingDefs,
            reports: [.html(path)],
            featureFactory: { StubFeature() }
        )

        #expect(FileManager.default.fileExists(atPath: path), "HTML report should exist")
        try? FileManager.default.removeItem(atPath: dir)
    }

    @Test("reports: [.json] writes JSON file with custom path")
    func reportsAutoWriteJSON() async throws {
        let dir = "/tmp/swift-gherkin-testing/test-json"
        let path = "\(dir)/report.json"
        try? FileManager.default.removeItem(atPath: dir)

        _ = try await FeatureExecutor<StubFeature>.run(
            source: .inline(Self.gherkin),
            definitions: Self.passingDefs,
            reports: [.json(path)],
            featureFactory: { StubFeature() }
        )

        #expect(FileManager.default.fileExists(atPath: path), "JSON report should exist")
        try? FileManager.default.removeItem(atPath: dir)
    }

    @Test("reports: all three formats writes all files")
    func reportsAutoWriteAllFormats() async throws {
        let dir = "/tmp/swift-gherkin-testing/test-all"
        let htmlPath = "\(dir)/r.html"
        let jsonPath = "\(dir)/r.json"
        let xmlPath = "\(dir)/r.xml"
        try? FileManager.default.removeItem(atPath: dir)

        _ = try await FeatureExecutor<StubFeature>.run(
            source: .inline(Self.gherkin),
            definitions: Self.passingDefs,
            reports: [.html(htmlPath), .json(jsonPath), .junitXML(xmlPath)],
            featureFactory: { StubFeature() }
        )

        #expect(FileManager.default.fileExists(atPath: htmlPath), "HTML report should exist")
        #expect(FileManager.default.fileExists(atPath: jsonPath), "JSON report should exist")
        #expect(FileManager.default.fileExists(atPath: xmlPath), "XML report should exist")
        try? FileManager.default.removeItem(atPath: dir)
    }

    @Test("reports: empty array writes no files (backward compat)")
    func reportsEmptyNoFiles() async throws {
        let dir = "/tmp/swift-gherkin-testing/test-empty"
        let path = "\(dir)/should-not-exist.html"
        try? FileManager.default.removeItem(atPath: dir)

        _ = try await FeatureExecutor<StubFeature>.run(
            source: .inline(Self.gherkin),
            definitions: Self.passingDefs,
            reports: [],
            featureFactory: { StubFeature() }
        )

        #expect(!FileManager.default.fileExists(atPath: path), "No report should be written")
        try? FileManager.default.removeItem(atPath: dir)
    }

    @Test("reports: [.html] default path writes to /tmp/.../StubFeature.html")
    func reportsDefaultPathHTML() async throws {
        let defaultPath = "/tmp/swift-gherkin-testing/reports/StubFeature.html"
        try? FileManager.default.removeItem(atPath: defaultPath)

        _ = try await FeatureExecutor<StubFeature>.run(
            source: .inline(Self.gherkin),
            definitions: Self.passingDefs,
            reports: [.html],
            featureFactory: { StubFeature() }
        )

        #expect(FileManager.default.fileExists(atPath: defaultPath), "HTML default path should exist")
        try? FileManager.default.removeItem(atPath: defaultPath)
    }

    @Test("reports: [.json] default path writes to /tmp/.../StubFeature.json")
    func reportsDefaultPathJSON() async throws {
        let defaultPath = "/tmp/swift-gherkin-testing/reports/StubFeature.json"
        try? FileManager.default.removeItem(atPath: defaultPath)

        _ = try await FeatureExecutor<StubFeature>.run(
            source: .inline(Self.gherkin),
            definitions: Self.passingDefs,
            reports: [.json],
            featureFactory: { StubFeature() }
        )

        #expect(FileManager.default.fileExists(atPath: defaultPath), "JSON default path should exist")
        try? FileManager.default.removeItem(atPath: defaultPath)
    }

    @Test("reports: [.junitXML] default path writes to /tmp/.../StubFeature.xml")
    func reportsDefaultPathXML() async throws {
        let defaultPath = "/tmp/swift-gherkin-testing/reports/StubFeature.xml"
        try? FileManager.default.removeItem(atPath: defaultPath)

        _ = try await FeatureExecutor<StubFeature>.run(
            source: .inline(Self.gherkin),
            definitions: Self.passingDefs,
            reports: [.junitXML],
            featureFactory: { StubFeature() }
        )

        #expect(FileManager.default.fileExists(atPath: defaultPath), "XML default path should exist")
        try? FileManager.default.removeItem(atPath: defaultPath)
    }

    @Test("reports: write to invalid path does not throw")
    func reportsInvalidPathNoThrow() async throws {
        // /dev/null/impossible is not a valid directory — createDirectory will fail
        _ = try await FeatureExecutor<StubFeature>.run(
            source: .inline(Self.gherkin),
            definitions: Self.passingDefs,
            reports: [.html("/dev/null/impossible/report.html")],
            featureFactory: { StubFeature() }
        )
        // If we reach here, the write error was silently caught — test passes
        #expect(Bool(true))
    }
}

private struct StubError: Error {}
