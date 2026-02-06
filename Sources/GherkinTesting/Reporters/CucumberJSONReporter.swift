// CucumberJSONReporter.swift
// GherkinTesting
//
// Copyright © 2026 Atelier Socle. MIT License.

import Foundation

/// Generates reports in the Cucumber JSON format.
///
/// The output is compatible with Cucumber Reports, ReportPortal, Allure,
/// and other tools that consume the standard Cucumber JSON format.
///
/// The report is an array of feature objects, each containing elements
/// (scenarios) with their steps, tags, and duration in nanoseconds.
///
/// ```swift
/// let reporter = CucumberJSONReporter()
/// // ... run tests with this reporter ...
/// let data = try await reporter.generateReport()
/// try data.write(to: URL(fileURLWithPath: "report.json"))
/// ```
public actor CucumberJSONReporter: GherkinReporter {
    private var runResult: TestRunResult?

    /// Creates a new Cucumber JSON reporter.
    public init() {}

    public func featureStarted(_ feature: FeatureResult) {}

    public func scenarioStarted(_ scenario: ScenarioResult) {}

    public func stepFinished(_ step: StepResult) {}

    public func scenarioFinished(_ scenario: ScenarioResult) {}

    public func featureFinished(_ feature: FeatureResult) {}

    public func testRunFinished(_ result: TestRunResult) {
        runResult = result
    }

    public func generateReport() throws -> Data {
        guard let runResult else {
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            return try encoder.encode([CucumberFeature]())
        }
        let features = runResult.featureResults.map { buildFeature($0) }
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return try encoder.encode(features)
    }
}

// MARK: - JSON Model Building

extension CucumberJSONReporter {
    private func buildFeature(_ feature: FeatureResult) -> CucumberFeature {
        let featureId = feature.name.lowercased()
            .split(separator: " ")
            .joined(separator: "-")
        let elements = feature.scenarioResults.map { scenario in
            buildElement(scenario, featureId: featureId)
        }
        return CucumberFeature(
            uri: "",
            id: featureId,
            keyword: "Feature",
            name: feature.name,
            tags: feature.tags.map { CucumberTag(name: $0, line: 1) },
            elements: elements
        )
    }

    private func buildElement(
        _ scenario: ScenarioResult,
        featureId: String
    ) -> CucumberElement {
        let scenarioId = scenario.name.lowercased()
            .split(separator: " ")
            .joined(separator: "-")
        let steps = scenario.stepResults.map { buildStep($0) }
        return CucumberElement(
            id: "\(featureId);\(scenarioId)",
            keyword: "Scenario",
            name: scenario.name,
            type: "scenario",
            tags: scenario.tags.map { CucumberTag(name: $0, line: 1) },
            steps: steps,
            before: [],
            after: []
        )
    }

    private func buildStep(_ step: StepResult) -> CucumberStep {
        let statusString = statusToString(step.status)
        let durationNanos = durationToNanoseconds(step.duration)
        var errorMessage: String?
        if case .failed(let failure) = step.status {
            errorMessage = failure.message
        }
        let locationString: String
        if let loc = step.location {
            locationString = "step:\(loc.line)"
        } else {
            locationString = ""
        }
        return CucumberStep(
            keyword: "Step ",
            name: step.step.text,
            match: CucumberStepMatch(location: locationString),
            result: CucumberStepResult(
                status: statusString,
                duration: durationNanos,
                errorMessage: errorMessage
            )
        )
    }

    private func statusToString(_ status: StepStatus) -> String {
        switch status {
        case .passed: return "passed"
        case .failed: return "failed"
        case .skipped: return "skipped"
        case .pending: return "pending"
        case .undefined: return "undefined"
        case .ambiguous: return "ambiguous"
        }
    }

    private func durationToNanoseconds(_ duration: Duration) -> Int64 {
        let components = duration.components
        return components.seconds * 1_000_000_000
            + components.attoseconds / 1_000_000_000
    }
}

// MARK: - Codable JSON Structures

extension CucumberJSONReporter {
    struct CucumberFeature: Codable, Sendable {
        let uri: String
        let id: String
        let keyword: String
        let name: String
        let tags: [CucumberTag]
        let elements: [CucumberElement]
    }

    struct CucumberElement: Codable, Sendable {
        let id: String
        let keyword: String
        let name: String
        let type: String
        let tags: [CucumberTag]
        let steps: [CucumberStep]
        let before: [CucumberHookResult]
        let after: [CucumberHookResult]
    }

    struct CucumberStep: Codable, Sendable {
        let keyword: String
        let name: String
        let match: CucumberStepMatch
        let result: CucumberStepResult
    }

    struct CucumberStepMatch: Codable, Sendable {
        let location: String
    }

    struct CucumberStepResult: Codable, Sendable {
        let status: String
        let duration: Int64
        let errorMessage: String?

        enum CodingKeys: String, CodingKey {
            case status
            case duration
            case errorMessage = "error_message"
        }
    }

    struct CucumberTag: Codable, Sendable {
        let name: String
        let line: Int
    }

    struct CucumberHookResult: Codable, Sendable {
        let match: CucumberStepMatch
        let result: CucumberStepResult
    }
}
