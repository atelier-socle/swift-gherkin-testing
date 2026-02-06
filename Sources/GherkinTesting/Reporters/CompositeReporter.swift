// CompositeReporter.swift
// GherkinTesting
//
// Copyright © 2026 Atelier Socle. MIT License.

import Foundation

/// A reporter that dispatches events to multiple child reporters.
///
/// Use `CompositeReporter` when you need multiple output formats from a
/// single test run (e.g. Cucumber JSON + JUnit XML + HTML simultaneously).
///
/// Events are forwarded to all child reporters in order. ``generateReport()``
/// returns the report from the first child reporter.
///
/// ```swift
/// let json = CucumberJSONReporter()
/// let xml = JUnitXMLReporter()
/// let html = HTMLReporter()
/// let composite = CompositeReporter(reporters: [json, xml, html])
/// let config = GherkinConfiguration(reporters: [composite])
/// ```
public actor CompositeReporter: GherkinReporter {
    private let reporters: [any GherkinReporter]

    /// Creates a composite reporter that forwards events to all given reporters.
    ///
    /// - Parameter reporters: The child reporters to dispatch events to.
    public init(reporters: [any GherkinReporter]) {
        self.reporters = reporters
    }

    public func featureStarted(_ feature: FeatureResult) async {
        for reporter in reporters {
            await reporter.featureStarted(feature)
        }
    }

    public func scenarioStarted(_ scenario: ScenarioResult) async {
        for reporter in reporters {
            await reporter.scenarioStarted(scenario)
        }
    }

    public func stepFinished(_ step: StepResult) async {
        for reporter in reporters {
            await reporter.stepFinished(step)
        }
    }

    public func scenarioFinished(_ scenario: ScenarioResult) async {
        for reporter in reporters {
            await reporter.scenarioFinished(scenario)
        }
    }

    public func featureFinished(_ feature: FeatureResult) async {
        for reporter in reporters {
            await reporter.featureFinished(feature)
        }
    }

    public func testRunFinished(_ result: TestRunResult) async {
        for reporter in reporters {
            await reporter.testRunFinished(result)
        }
    }

    /// Generates the report from the first child reporter.
    ///
    /// - Returns: The report data from the first reporter, or empty data if no reporters.
    /// - Throws: If the first reporter's generation fails.
    public func generateReport() async throws -> Data {
        guard let first = reporters.first else {
            return Data()
        }
        return try await first.generateReport()
    }
}
