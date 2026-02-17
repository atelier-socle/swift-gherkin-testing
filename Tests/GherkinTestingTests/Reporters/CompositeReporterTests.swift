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

// MARK: - Test Helpers

private func makePickleStep(_ text: String, id: String = "step-1") -> PickleStep {
    PickleStep(id: id, text: text, argument: nil, astNodeIds: [])
}

private func makeStepResult(
    text: String,
    status: StepStatus = .passed,
    duration: Duration = .milliseconds(100),
    location: Location? = Location(line: 10)
) -> StepResult {
    StepResult(
        step: makePickleStep(text),
        status: status,
        duration: duration,
        location: location
    )
}

private func makeScenarioResult(
    name: String = "Test Scenario",
    stepResults: [StepResult] = [],
    tags: [String] = []
) -> ScenarioResult {
    ScenarioResult(name: name, stepResults: stepResults, tags: tags)
}

private func makeFeatureResult(
    name: String = "Test Feature",
    scenarioResults: [ScenarioResult] = [],
    tags: [String] = []
) -> FeatureResult {
    FeatureResult(name: name, scenarioResults: scenarioResults, tags: tags)
}

private func makeTestRunResult(
    featureResults: [FeatureResult] = [],
    duration: Duration = .seconds(1)
) -> TestRunResult {
    TestRunResult(featureResults: featureResults, duration: duration)
}

/// A spy reporter that tracks which events were received.
private actor SpyReporter: GherkinReporter {
    var events: [String] = []
    var runResult: TestRunResult?

    func featureStarted(_ feature: FeatureResult) {
        events.append("featureStarted:\(feature.name)")
    }

    func scenarioStarted(_ scenario: ScenarioResult) {
        events.append("scenarioStarted:\(scenario.name)")
    }

    func stepFinished(_ step: StepResult) {
        events.append("stepFinished:\(step.step.text)")
    }

    func scenarioFinished(_ scenario: ScenarioResult) {
        events.append("scenarioFinished:\(scenario.name)")
    }

    func featureFinished(_ feature: FeatureResult) {
        events.append("featureFinished:\(feature.name)")
    }

    func testRunFinished(_ result: TestRunResult) {
        events.append("testRunFinished")
        runResult = result
    }

    func generateReport() throws -> Data {
        Data("spy-report".utf8)
    }
}

@Suite("CompositeReporter")
struct CompositeReporterTests {

    @Test("dispatches featureStarted to all reporters")
    func featureStarted() async throws {
        let spy1 = SpyReporter()
        let spy2 = SpyReporter()
        let composite = CompositeReporter(reporters: [spy1, spy2])

        let feature = makeFeatureResult(name: "Login")
        await composite.featureStarted(feature)

        let events1 = await spy1.events
        let events2 = await spy2.events
        #expect(events1 == ["featureStarted:Login"])
        #expect(events2 == ["featureStarted:Login"])
    }

    @Test("dispatches scenarioStarted to all reporters")
    func scenarioStarted() async throws {
        let spy1 = SpyReporter()
        let spy2 = SpyReporter()
        let composite = CompositeReporter(reporters: [spy1, spy2])

        let scenario = makeScenarioResult(name: "S1")
        await composite.scenarioStarted(scenario)

        let events1 = await spy1.events
        let events2 = await spy2.events
        #expect(events1 == ["scenarioStarted:S1"])
        #expect(events2 == ["scenarioStarted:S1"])
    }

    @Test("dispatches stepFinished to all reporters")
    func stepFinished() async throws {
        let spy1 = SpyReporter()
        let spy2 = SpyReporter()
        let composite = CompositeReporter(reporters: [spy1, spy2])

        let step = makeStepResult(text: "the user logs in")
        await composite.stepFinished(step)

        let events1 = await spy1.events
        let events2 = await spy2.events
        #expect(events1 == ["stepFinished:the user logs in"])
        #expect(events2 == ["stepFinished:the user logs in"])
    }

    @Test("dispatches scenarioFinished to all reporters")
    func scenarioFinished() async throws {
        let spy1 = SpyReporter()
        let spy2 = SpyReporter()
        let composite = CompositeReporter(reporters: [spy1, spy2])

        let scenario = makeScenarioResult(name: "S1")
        await composite.scenarioFinished(scenario)

        let events1 = await spy1.events
        let events2 = await spy2.events
        #expect(events1 == ["scenarioFinished:S1"])
        #expect(events2 == ["scenarioFinished:S1"])
    }

    @Test("dispatches featureFinished to all reporters")
    func featureFinished() async throws {
        let spy1 = SpyReporter()
        let spy2 = SpyReporter()
        let composite = CompositeReporter(reporters: [spy1, spy2])

        let feature = makeFeatureResult(name: "Login")
        await composite.featureFinished(feature)

        let events1 = await spy1.events
        let events2 = await spy2.events
        #expect(events1 == ["featureFinished:Login"])
        #expect(events2 == ["featureFinished:Login"])
    }

    @Test("dispatches testRunFinished to all reporters")
    func testRunFinished() async throws {
        let spy1 = SpyReporter()
        let spy2 = SpyReporter()
        let composite = CompositeReporter(reporters: [spy1, spy2])

        let result = makeTestRunResult()
        await composite.testRunFinished(result)

        let events1 = await spy1.events
        let events2 = await spy2.events
        #expect(events1 == ["testRunFinished"])
        #expect(events2 == ["testRunFinished"])
    }

    @Test("generateReport returns first reporter's report")
    func generateReport() async throws {
        let spy1 = SpyReporter()
        let spy2 = SpyReporter()
        let composite = CompositeReporter(reporters: [spy1, spy2])

        let data = try await composite.generateReport()
        let text = String(data: data, encoding: .utf8)
        #expect(text == "spy-report")
    }

    @Test("generateReport with empty reporters returns empty data")
    func generateReportEmpty() async throws {
        let composite = CompositeReporter(reporters: [])
        let data = try await composite.generateReport()
        #expect(data.isEmpty)
    }

    @Test("dispatches full lifecycle in order")
    func fullLifecycle() async throws {
        let spy = SpyReporter()
        let composite = CompositeReporter(reporters: [spy])

        let feature = makeFeatureResult(name: "F1")
        let scenario = makeScenarioResult(name: "S1")
        let step = makeStepResult(text: "step A")
        let result = makeTestRunResult()

        await composite.featureStarted(feature)
        await composite.scenarioStarted(scenario)
        await composite.stepFinished(step)
        await composite.scenarioFinished(scenario)
        await composite.featureFinished(feature)
        await composite.testRunFinished(result)

        let events = await spy.events
        #expect(
            events == [
                "featureStarted:F1",
                "scenarioStarted:S1",
                "stepFinished:step A",
                "scenarioFinished:S1",
                "featureFinished:F1",
                "testRunFinished"
            ])
    }

    @Test("works with real reporters")
    func withRealReporters() async throws {
        let json = CucumberJSONReporter()
        let xml = JUnitXMLReporter()
        let html = HTMLReporter()
        let composite = CompositeReporter(reporters: [json, xml, html])

        let step = makeStepResult(text: "the user logs in")
        let scenario = makeScenarioResult(name: "Login", stepResults: [step])
        let feature = makeFeatureResult(name: "Auth", scenarioResults: [scenario])
        let result = makeTestRunResult(featureResults: [feature])

        await composite.testRunFinished(result)

        // Composite returns first reporter's output (JSON)
        let compositeData = try await composite.generateReport()
        let compositeText = try #require(String(data: compositeData, encoding: .utf8))
        #expect(compositeText.contains("\"keyword\" : \"Feature\""))

        // Individual reporters also work
        let xmlData = try await xml.generateReport()
        let xmlText = try #require(String(data: xmlData, encoding: .utf8))
        #expect(xmlText.contains("<testsuites>"))

        let htmlData = try await html.generateReport()
        let htmlText = try #require(String(data: htmlData, encoding: .utf8))
        #expect(htmlText.contains("<!DOCTYPE html>"))
    }
}
