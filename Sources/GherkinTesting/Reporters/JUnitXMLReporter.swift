// JUnitXMLReporter.swift
// GherkinTesting
//
// Copyright © 2026 Atelier Socle. MIT License.

import Foundation

/// Generates reports in the JUnit XML format.
///
/// The output is compatible with CI/CD tools such as GitHub Actions,
/// Jenkins, Azure DevOps, and GitLab CI.
///
/// The XML follows the standard JUnit schema:
/// - `<testsuites>` root element
/// - `<testsuite>` per feature with aggregate counts
/// - `<testcase>` per scenario with timing
/// - `<failure>` elements for failed steps
/// - `<skipped/>` elements for skipped scenarios
///
/// ```swift
/// let reporter = JUnitXMLReporter()
/// // ... run tests with this reporter ...
/// let data = try await reporter.generateReport()
/// try data.write(to: URL(fileURLWithPath: "report.xml"))
/// ```
public actor JUnitXMLReporter: GherkinReporter {
    private var runResult: TestRunResult?

    /// Creates a new JUnit XML reporter.
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
            let xml = """
                <?xml version="1.0" encoding="UTF-8"?>
                <testsuites>
                </testsuites>
                """
            guard let data = xml.data(using: .utf8) else {
                throw ReporterError.encodingFailed
            }
            return data
        }
        let xml = buildXML(runResult)
        guard let data = xml.data(using: .utf8) else {
            throw ReporterError.encodingFailed
        }
        return data
    }
}

// MARK: - XML Building

extension JUnitXMLReporter {
    private func buildXML(_ result: TestRunResult) -> String {
        var xml = "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n"
        xml += "<testsuites>\n"
        for feature in result.featureResults {
            xml += buildTestSuite(feature)
        }
        xml += "</testsuites>\n"
        return xml
    }

    private func buildTestSuite(_ feature: FeatureResult) -> String {
        let scenarios = feature.scenarioResults
        let tests = scenarios.count
        let failures = scenarios.filter { isFailedStatus($0.status) }.count
        let errors = 0
        let skipped = scenarios.filter { $0.status == .skipped }.count
        let time = formatDuration(feature.duration)
        let name = escapeXML(feature.name)

        var xml = "  <testsuite"
        xml += " name=\"Feature: \(name)\""
        xml += " tests=\"\(tests)\""
        xml += " failures=\"\(failures)\""
        xml += " errors=\"\(errors)\""
        xml += " skipped=\"\(skipped)\""
        xml += " time=\"\(time)\""
        xml += ">\n"

        for scenario in scenarios {
            xml += buildTestCase(scenario, featureName: feature.name)
        }

        xml += "  </testsuite>\n"
        return xml
    }

    private func buildTestCase(_ scenario: ScenarioResult, featureName: String) -> String {
        let name = escapeXML(scenario.name)
        let time = formatDuration(scenario.duration)
        let classname = escapeXML(featureName)

        var xml = "    <testcase"
        xml += " name=\"Scenario: \(name)\""
        xml += " classname=\"\(classname)\""
        xml += " time=\"\(time)\""

        if scenario.status == .skipped {
            xml += ">\n"
            xml += "      <skipped/>\n"
            xml += "    </testcase>\n"
        } else if isFailedStatus(scenario.status) {
            xml += ">\n"
            let failureInfo = collectFailureInfo(scenario)
            let message = escapeXML(failureInfo.message)
            let detail = escapeXML(failureInfo.detail)
            xml += "      <failure"
            xml += " message=\"\(message)\""
            xml += " type=\"\(escapeXML(failureInfo.type))\""
            xml += ">\(detail)</failure>\n"
            xml += "    </testcase>\n"
        } else if scenario.status == .pending {
            xml += ">\n"
            xml += "      <skipped message=\"pending\"/>\n"
            xml += "    </testcase>\n"
        } else if scenario.status == .undefined {
            xml += ">\n"
            xml += "      <skipped message=\"undefined\"/>\n"
            xml += "    </testcase>\n"
        } else {
            xml += "/>\n"
        }

        return xml
    }

    private func isFailedStatus(_ status: StepStatus) -> Bool {
        switch status {
        case .failed, .ambiguous: return true
        default: return false
        }
    }

    private func collectFailureInfo(_ scenario: ScenarioResult) -> FailureInfo {
        for stepResult in scenario.stepResults {
            if case .failed(let failure) = stepResult.status {
                return FailureInfo(
                    message: failure.message,
                    type: "StepFailure",
                    detail: "Step: \(stepResult.step.text)\n\(failure.message)"
                )
            }
            if case .ambiguous = stepResult.status {
                return FailureInfo(
                    message: "Ambiguous step: \(stepResult.step.text)",
                    type: "AmbiguousStepError",
                    detail: "Step: \(stepResult.step.text)\nMultiple matching step definitions found"
                )
            }
        }
        return FailureInfo(message: "Unknown failure", type: "Error", detail: "")
    }

    private func formatDuration(_ duration: Duration) -> String {
        let components = duration.components
        let totalSeconds =
            Double(components.seconds)
            + Double(components.attoseconds) / 1e18
        return String(format: "%.3f", totalSeconds)
    }

    private func escapeXML(_ string: String) -> String {
        var result = string
        result = result.replacing("&", with: "&amp;")
        result = result.replacing("<", with: "&lt;")
        result = result.replacing(">", with: "&gt;")
        result = result.replacing("\"", with: "&quot;")
        result = result.replacing("'", with: "&apos;")
        return result
    }
}

// MARK: - Supporting Types

extension JUnitXMLReporter {
    private struct FailureInfo {
        let message: String
        let type: String
        let detail: String
    }
}

/// Errors that can occur during report generation.
public enum ReporterError: Error, Sendable {
    /// The report content could not be encoded to UTF-8.
    case encodingFailed
}
