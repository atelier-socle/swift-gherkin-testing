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

import Testing

@testable import GherkinTesting

/// A feature type that captures step arguments for verification.
private struct ArgFeature: GherkinFeature {
    var capturedTable: DataTable?
    var capturedDocString: String?
    var capturedArgs: [String] = []
}

/// Helper to create a DataTable from string arrays.
private func makeTable(_ rows: [[String]]) -> DataTable {
    DataTable(
        location: Location(line: 1, column: 1),
        rows: rows.enumerated().map { index, values in
            TableRow(
                location: Location(line: index + 1),
                cells: values.map { TableCell(location: Location(line: index + 1), value: $0) }
            )
        }
    )
}

@Suite("StepArgument Integration — StepExecutor")
struct StepArgumentExecutorTests {

    @Test("Step with DataTable passes StepArgument.dataTable to handler")
    func executorDataTable() async throws {
        let table = makeTable([
            ["name", "email"],
            ["alice", "alice@example.com"]
        ])

        let definition = StepDefinition<ArgFeature>(
            pattern: .exact("the following users exist"),
            sourceLocation: Location(line: 1),
            handler: { feature, _, stepArg in
                feature.capturedTable = stepArg?.dataTable
            }
        )

        let executor = StepExecutor(definitions: [definition])
        let step = PickleStep(
            id: "s1",
            text: "the following users exist",
            argument: .dataTable(table),
            astNodeIds: []
        )

        var feature = ArgFeature()
        try await executor.execute(step, on: &feature)

        let captured = try #require(feature.capturedTable)
        #expect(captured.headers == ["name", "email"])
        #expect(captured.asDictionaries == [["name": "alice", "email": "alice@example.com"]])
    }

    @Test("Step with DocString passes StepArgument.docString to handler")
    func executorDocString() async throws {
        let doc = DocString(
            location: Location(line: 1, column: 1),
            mediaType: "json",
            content: "{\"key\": \"value\"}",
            delimiter: "\"\"\""
        )

        let definition = StepDefinition<ArgFeature>(
            pattern: .exact("the API receives the payload"),
            sourceLocation: Location(line: 1),
            handler: { feature, _, stepArg in
                feature.capturedDocString = stepArg?.docString
            }
        )

        let executor = StepExecutor(definitions: [definition])
        let step = PickleStep(
            id: "s1",
            text: "the API receives the payload",
            argument: .docString(doc),
            astNodeIds: []
        )

        var feature = ArgFeature()
        try await executor.execute(step, on: &feature)

        #expect(feature.capturedDocString == "{\"key\": \"value\"}")
    }

    @Test("Step without argument passes nil StepArgument to handler")
    func executorNoArgument() async throws {
        let definition = StepDefinition<ArgFeature>(
            pattern: .exact("a plain step"),
            sourceLocation: Location(line: 1),
            handler: { feature, _, stepArg in
                feature.capturedTable = stepArg?.dataTable
                feature.capturedDocString = stepArg?.docString
            }
        )

        let executor = StepExecutor(definitions: [definition])
        let step = PickleStep(id: "s1", text: "a plain step", argument: nil, astNodeIds: [])

        var feature = ArgFeature()
        try await executor.execute(step, on: &feature)

        #expect(feature.capturedTable == nil)
        #expect(feature.capturedDocString == nil)
    }

    @Test("Step with DataTable and captured text arguments both available")
    func executorMixedArgs() async throws {
        let table = makeTable([["key", "value"], ["a", "1"]])

        let definition = StepDefinition<ArgFeature>(
            pattern: .cucumberExpression("I have {int} items with details"),
            sourceLocation: Location(line: 1),
            handler: { feature, args, stepArg in
                feature.capturedArgs = args
                feature.capturedTable = stepArg?.dataTable
            }
        )

        let executor = StepExecutor(definitions: [definition])
        let step = PickleStep(
            id: "s1",
            text: "I have 5 items with details",
            argument: .dataTable(table),
            astNodeIds: []
        )

        var feature = ArgFeature()
        try await executor.execute(step, on: &feature)

        #expect(feature.capturedArgs == ["5"])
        let captured = try #require(feature.capturedTable)
        #expect(captured.asDictionaries == [["key": "a", "value": "1"]])
    }
}

@Suite("StepArgument Integration — TestRunner")
struct StepArgumentRunnerTests {

    @Test("TestRunner passes DataTable through to handler in full scenario")
    func runnerDataTable() async throws {
        let table = makeTable([
            ["username", "password"],
            ["admin", "secret"]
        ])

        let pickle = Pickle(
            id: "p1",
            uri: "",
            name: "Scenario with table",
            language: "en",
            tags: [],
            steps: [
                PickleStep(
                    id: "s1",
                    text: "the following accounts exist",
                    argument: .dataTable(table),
                    astNodeIds: []
                )
            ],
            astNodeIds: []
        )

        actor TableCapture {
            var table: DataTable?
            func set(_ t: DataTable?) { table = t }
            func get() -> DataTable? { table }
        }
        let capture = TableCapture()

        let definition = StepDefinition<ArgFeature>(
            pattern: .exact("the following accounts exist"),
            sourceLocation: Location(line: 1),
            handler: { _, _, stepArg in
                await capture.set(stepArg?.dataTable)
            }
        )

        let runner = TestRunner<ArgFeature>(definitions: [definition])
        let feature = ArgFeature()
        let result = try await runner.run(
            pickles: [pickle],
            featureName: "Table Test",
            featureTags: [],
            feature: feature
        )

        #expect(result.passedCount == 1)
        let captured = await capture.get()
        let table2 = try #require(captured)
        #expect(table2.headers == ["username", "password"])
    }

    @Test("TestRunner passes DocString through to handler in full scenario")
    func runnerDocString() async throws {
        let doc = DocString(
            location: Location(line: 1, column: 1),
            mediaType: nil,
            content: "Hello World",
            delimiter: "\"\"\""
        )

        let pickle = Pickle(
            id: "p1",
            uri: "",
            name: "Scenario with docstring",
            language: "en",
            tags: [],
            steps: [
                PickleStep(
                    id: "s1",
                    text: "the message is",
                    argument: .docString(doc),
                    astNodeIds: []
                )
            ],
            astNodeIds: []
        )

        actor StringCapture {
            var value: String?
            func set(_ s: String?) { value = s }
            func get() -> String? { value }
        }
        let capture = StringCapture()

        let definition = StepDefinition<ArgFeature>(
            pattern: .exact("the message is"),
            sourceLocation: Location(line: 1),
            handler: { _, _, stepArg in
                await capture.set(stepArg?.docString)
            }
        )

        let runner = TestRunner<ArgFeature>(definitions: [definition])
        let feature = ArgFeature()
        let result = try await runner.run(
            pickles: [pickle],
            featureName: "DocString Test",
            featureTags: [],
            feature: feature
        )

        #expect(result.passedCount == 1)
        let captured = await capture.get()
        #expect(captured == "Hello World")
    }
}
