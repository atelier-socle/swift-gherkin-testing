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

/// Thread-safe log for tracking hook execution order.
actor HookLog {
    var entries: [String] = []

    func append(_ entry: String) {
        entries.append(entry)
    }
}

@Suite("HookRegistry")
struct HookRegistryTests {

    // MARK: - Before Hooks

    @Test("before hooks execute in registration order")
    func beforeHookOrder() async throws {
        let log = HookLog()
        var registry = HookRegistry()
        registry.addBefore(Hook(scope: .scenario) { await log.append("first") })
        registry.addBefore(Hook(scope: .scenario) { await log.append("second") })
        registry.addBefore(Hook(scope: .scenario) { await log.append("third") })

        try await registry.executeBefore(scope: .scenario, tags: [])
        let entries = await log.entries
        #expect(entries == ["first", "second", "third"])
    }

    @Test("before hooks only execute for matching scope")
    func beforeHookScope() async throws {
        let log = HookLog()
        var registry = HookRegistry()
        registry.addBefore(Hook(scope: .feature) { await log.append("feature") })
        registry.addBefore(Hook(scope: .scenario) { await log.append("scenario") })
        registry.addBefore(Hook(scope: .step) { await log.append("step") })

        try await registry.executeBefore(scope: .scenario, tags: [])
        let entries = await log.entries
        #expect(entries == ["scenario"])
    }

    // MARK: - After Hooks

    @Test("after hooks execute in reverse order (LIFO)")
    func afterHookReverseOrder() async throws {
        let log = HookLog()
        var registry = HookRegistry()
        registry.addAfter(Hook(scope: .scenario) { await log.append("first") })
        registry.addAfter(Hook(scope: .scenario) { await log.append("second") })
        registry.addAfter(Hook(scope: .scenario) { await log.append("third") })

        try await registry.executeAfter(scope: .scenario, tags: [])
        let entries = await log.entries
        #expect(entries == ["third", "second", "first"])
    }

    @Test("after hooks only execute for matching scope")
    func afterHookScope() async throws {
        let log = HookLog()
        var registry = HookRegistry()
        registry.addAfter(Hook(scope: .feature) { await log.append("feature") })
        registry.addAfter(Hook(scope: .scenario) { await log.append("scenario") })
        registry.addAfter(Hook(scope: .step) { await log.append("step") })

        try await registry.executeAfter(scope: .feature, tags: [])
        let entries = await log.entries
        #expect(entries == ["feature"])
    }

    @Test("after hooks all execute even if one throws")
    func afterHooksRunDespiteError() async throws {
        struct HookError: Error {}
        let log = HookLog()
        var registry = HookRegistry()
        registry.addAfter(Hook(scope: .scenario) { await log.append("first") })
        registry.addAfter(
            Hook(scope: .scenario) {
                await log.append("throws")
                throw HookError()
            })
        registry.addAfter(Hook(scope: .scenario) { await log.append("third") })

        await #expect(throws: HookError.self) {
            try await registry.executeAfter(scope: .scenario, tags: [])
        }
        // All hooks should have executed (reverse: third, throws, first)
        let entries = await log.entries
        #expect(entries == ["third", "throws", "first"])
    }

    // MARK: - Tag Filtering

    @Test("hook with tag filter only runs when tags match")
    func hookWithTagFilter() async throws {
        let log = HookLog()
        var registry = HookRegistry()
        registry.addBefore(
            Hook(
                scope: .scenario,
                tagFilter: try TagFilter("@smoke"),
                handler: { await log.append("smoke-hook") }
            ))

        try await registry.executeBefore(scope: .scenario, tags: ["@smoke"])
        let entries = await log.entries
        #expect(entries == ["smoke-hook"])
    }

    @Test("hook with tag filter skipped when tags don't match")
    func hookWithTagFilterSkipped() async throws {
        let log = HookLog()
        var registry = HookRegistry()
        registry.addBefore(
            Hook(
                scope: .scenario,
                tagFilter: try TagFilter("@smoke"),
                handler: { await log.append("smoke-hook") }
            ))

        try await registry.executeBefore(scope: .scenario, tags: ["@login"])
        let entries = await log.entries
        #expect(entries.isEmpty)
    }

    @Test("hooks with and without tag filters mix correctly")
    func mixedTagFilters() async throws {
        let log = HookLog()
        var registry = HookRegistry()
        registry.addBefore(Hook(scope: .scenario) { await log.append("always") })
        registry.addBefore(
            Hook(
                scope: .scenario,
                tagFilter: try TagFilter("@smoke"),
                handler: { await log.append("smoke-only") }
            ))
        registry.addBefore(Hook(scope: .scenario) { await log.append("always2") })

        try await registry.executeBefore(scope: .scenario, tags: ["@login"])
        let entries = await log.entries
        #expect(entries == ["always", "always2"])
    }

    // MARK: - Feature / Scenario / Step Scopes

    @Test("feature scope hooks execute once")
    func featureScopeHooks() async throws {
        let log = HookLog()
        var registry = HookRegistry()
        registry.addBefore(Hook(scope: .feature) { await log.append("before-feature") })
        registry.addAfter(Hook(scope: .feature) { await log.append("after-feature") })

        try await registry.executeBefore(scope: .feature, tags: [])
        try await registry.executeAfter(scope: .feature, tags: [])
        let entries = await log.entries
        #expect(entries == ["before-feature", "after-feature"])
    }

    @Test("step scope hooks execute per step")
    func stepScopeHooks() async throws {
        let log = HookLog()
        var registry = HookRegistry()
        registry.addBefore(Hook(scope: .step) { await log.append("before-step") })
        registry.addAfter(Hook(scope: .step) { await log.append("after-step") })

        for _ in 0..<3 {
            try await registry.executeBefore(scope: .step, tags: [])
            try await registry.executeAfter(scope: .step, tags: [])
        }
        let entries = await log.entries
        #expect(
            entries == [
                "before-step", "after-step",
                "before-step", "after-step",
                "before-step", "after-step"
            ])
    }

    // MARK: - Empty Registry

    @Test("empty registry executes without error")
    func emptyRegistry() async throws {
        let registry = HookRegistry()
        try await registry.executeBefore(scope: .scenario, tags: [])
        try await registry.executeAfter(scope: .scenario, tags: [])
    }

    // MARK: - Initialization

    @Test("initialization with hooks arrays")
    func initWithHooks() async throws {
        let log = HookLog()
        let registry = HookRegistry(
            beforeHooks: [Hook(scope: .scenario) { await log.append("before") }],
            afterHooks: [Hook(scope: .scenario) { await log.append("after") }]
        )

        try await registry.executeBefore(scope: .scenario, tags: [])
        try await registry.executeAfter(scope: .scenario, tags: [])
        let entries = await log.entries
        #expect(entries == ["before", "after"])
    }
}
