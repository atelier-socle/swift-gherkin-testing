// Hooks.swift
// GherkinTestingDemoTests
//
// Copyright © 2026 Atelier Socle. MIT License.

import GherkinTesting

// MARK: - @Before / @After Demo
//
// Hook macros generate `static let __hook_*` properties containing `Hook` values.
// When hooks are defined inside a @Feature struct, the macro collects them into
// a `static var __hooks: HookRegistry` and passes them to FeatureExecutor.
//
// Standalone hook structs (like this one) can be used with the manual API:
//   var hooks = HookRegistry()
//   hooks.addBefore(DemoHooks.__hook_resetState)
//   hooks.addAfter(DemoHooks.__hook_cleanup)
//   let runner = TestRunner(definitions: defs, hooks: hooks)

/// Standalone hook definitions demonstrating @Before/@After macros.
struct DemoHooks {

    @Before(.scenario)
    static func resetState() async throws {
        await Task.yield()
    }

    @Before(.scenario, tags: "@smoke")
    static func setupSmoke() async throws {
        await Task.yield()
    }

    @After(.scenario)
    static func cleanup() async throws {
        await Task.yield()
    }
}
