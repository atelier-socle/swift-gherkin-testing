// GherkinConfigurationCustomTypesTests.swift
// GherkinTestingTests
//
// Copyright © 2026 Atelier Socle. MIT License.

import Testing

@testable import GherkinTesting

/// A minimal feature for custom type integration tests.
private struct CustomTypeFeature: GherkinFeature {
    var lastColor: String = ""
    var lastAmount: String = ""
}

/// Helper to build a Pickle.
private func makePickle(
    name: String,
    steps: [PickleStep],
    tags: [PickleTag] = []
) -> Pickle {
    Pickle(
        id: "pickle-1",
        uri: "test.feature",
        name: name,
        language: "en",
        tags: tags,
        steps: steps,
        astNodeIds: []
    )
}

/// Helper to build a PickleStep.
private func makeStep(_ text: String) -> PickleStep {
    PickleStep(id: "step", text: text, argument: nil, astNodeIds: [])
}

@Suite("GherkinConfiguration Custom Types")
struct GherkinConfigurationCustomTypesTests {

    // MARK: - Configuration Storage

    @Test("default config has empty parameterTypes")
    func defaultConfigEmpty() {
        let config = GherkinConfiguration()
        #expect(config.parameterTypes.isEmpty)
    }

    @Test("static default has empty parameterTypes")
    func staticDefaultEmpty() {
        #expect(GherkinConfiguration.default.parameterTypes.isEmpty)
    }

    @Test("config stores custom types")
    func configStoresTypes() {
        let config = GherkinConfiguration(
            parameterTypes: [
                .type("color", matching: "red|green|blue"),
                .type("amount", matching: #"\d+\.\d{2}"#)
            ]
        )
        #expect(config.parameterTypes.count == 2)
        #expect(config.parameterTypes[0].name == "color")
        #expect(config.parameterTypes[1].name == "amount")
    }

    @Test("config with all parameters")
    func configWithAllParams() {
        let config = GherkinConfiguration(
            reporters: [],
            parameterTypes: [.type("color", matching: "red")],
            tagFilter: nil,
            dryRun: true
        )
        #expect(config.parameterTypes.count == 1)
        #expect(config.dryRun == true)
    }

    // MARK: - Integration with TestRunner

    @Test("custom type matches step via TestRunner")
    func customTypeMatches() async throws {
        let log = TestLog()
        let definitions: [StepDefinition<CustomTypeFeature>] = [
            StepDefinition(
                pattern: .cucumberExpression("the item is {color}"),
                sourceLocation: Location(line: 1),
                handler: { feature, args, _ in
                    feature.lastColor = args[0]
                    await log.append("color:\(args[0])")
                }
            )
        ]

        let config = GherkinConfiguration(
            parameterTypes: [.type("color", matching: "red|green|blue")]
        )
        let runner = TestRunner<CustomTypeFeature>(
            definitions: definitions,
            configuration: config
        )

        let pickle = makePickle(name: "Color test", steps: [makeStep("the item is red")])
        let result = try await runner.run(
            pickles: [pickle],
            featureName: "Test",
            featureTags: [],
            feature: CustomTypeFeature()
        )

        #expect(result.passedCount == 1)
        #expect(result.failedCount == 0)
        let entries = await log.entries
        #expect(entries == ["color:red"])
    }

    @Test("custom type rejects non-matching value")
    func customTypeRejectsNonMatch() async throws {
        let definitions: [StepDefinition<CustomTypeFeature>] = [
            StepDefinition(
                pattern: .cucumberExpression("the item is {color}"),
                sourceLocation: Location(line: 1),
                handler: { _, _, _ in }
            )
        ]

        let config = GherkinConfiguration(
            parameterTypes: [.type("color", matching: "red|green|blue")]
        )
        let runner = TestRunner<CustomTypeFeature>(
            definitions: definitions,
            configuration: config
        )

        // "purple" doesn't match "red|green|blue"
        let pickle = makePickle(name: "Bad color", steps: [makeStep("the item is purple")])
        let result = try await runner.run(
            pickles: [pickle],
            featureName: "Test",
            featureTags: [],
            feature: CustomTypeFeature()
        )

        #expect(result.passedCount == 0)
        let stepResult = try #require(result.featureResults.first?.scenarioResults.first?.stepResults.first)
        #expect(stepResult.status == .undefined)
    }

    @Test("multiple custom types in one config")
    func multipleCustomTypes() async throws {
        let log = TestLog()
        let definitions: [StepDefinition<CustomTypeFeature>] = [
            StepDefinition(
                pattern: .cucumberExpression("the {color} item costs {amount}"),
                sourceLocation: Location(line: 1),
                handler: { feature, args, _ in
                    feature.lastColor = args[0]
                    feature.lastAmount = args[1]
                    await log.append("color:\(args[0]),amount:\(args[1])")
                }
            )
        ]

        let config = GherkinConfiguration(
            parameterTypes: [
                .type("color", matching: "red|green|blue"),
                .type("amount", matching: #"\d+\.\d{2}"#)
            ]
        )
        let runner = TestRunner<CustomTypeFeature>(
            definitions: definitions,
            configuration: config
        )

        let pickle = makePickle(name: "Multi", steps: [makeStep("the red item costs 9.99")])
        let result = try await runner.run(
            pickles: [pickle],
            featureName: "Test",
            featureTags: [],
            feature: CustomTypeFeature()
        )

        #expect(result.passedCount == 1)
        let entries = await log.entries
        #expect(entries == ["color:red,amount:9.99"])
    }

    @Test("duplicate of built-in type is silently skipped")
    func duplicateBuiltInSkipped() async throws {
        let definitions: [StepDefinition<CustomTypeFeature>] = [
            StepDefinition(
                pattern: .cucumberExpression("there are {int} items"),
                sourceLocation: Location(line: 1),
                handler: { _, _, _ in }
            )
        ]

        // Trying to re-register "int" should be silently skipped
        let config = GherkinConfiguration(
            parameterTypes: [.type("int", matching: "CUSTOM")]
        )
        let runner = TestRunner<CustomTypeFeature>(
            definitions: definitions,
            configuration: config
        )

        // The built-in {int} should still work (matches \d+)
        let pickle = makePickle(name: "Built-in wins", steps: [makeStep("there are 5 items")])
        let result = try await runner.run(
            pickles: [pickle],
            featureName: "Test",
            featureTags: [],
            feature: CustomTypeFeature()
        )

        #expect(result.passedCount == 1)
    }

    @Test("custom type with dry-run mode")
    func customTypeWithDryRun() async throws {
        let definitions: [StepDefinition<CustomTypeFeature>] = [
            StepDefinition(
                pattern: .cucumberExpression("the item is {color}"),
                sourceLocation: Location(line: 1),
                handler: { _, _, _ in }
            )
        ]

        let config = GherkinConfiguration(
            parameterTypes: [.type("color", matching: "red|green|blue")],
            dryRun: true
        )
        let runner = TestRunner<CustomTypeFeature>(
            definitions: definitions,
            configuration: config
        )

        let pickle = makePickle(name: "Dry run", steps: [makeStep("the item is green")])
        let result = try await runner.run(
            pickles: [pickle],
            featureName: "Test",
            featureTags: [],
            feature: CustomTypeFeature()
        )

        // Dry-run matches but doesn't execute
        #expect(result.passedCount == 1)
    }

    @Test("empty parameterTypes array works normally")
    func emptyParameterTypes() async throws {
        let definitions: [StepDefinition<CustomTypeFeature>] = [
            StepDefinition(
                pattern: .exact("hello world"),
                sourceLocation: Location(line: 1),
                handler: { _, _, _ in }
            )
        ]

        let config = GherkinConfiguration(parameterTypes: [])
        let runner = TestRunner<CustomTypeFeature>(
            definitions: definitions,
            configuration: config
        )

        let pickle = makePickle(name: "Basic", steps: [makeStep("hello world")])
        let result = try await runner.run(
            pickles: [pickle],
            featureName: "Test",
            featureTags: [],
            feature: CustomTypeFeature()
        )

        #expect(result.passedCount == 1)
    }
}

/// Thread-safe log for integration tests.
private actor TestLog {
    var entries: [String] = []

    func append(_ entry: String) {
        entries.append(entry)
    }
}
