// HookRegistry.swift
// GherkinTesting
//
// Copyright © 2026 Atelier Socle. MIT License.

/// The scope at which a hook executes during a test run.
///
/// Hooks can be registered to execute at the feature, scenario, or step level,
/// running before and/or after the corresponding phase of execution.
@frozen
public enum HookScope: String, Sendable, Equatable, Hashable {
    /// Executes once at the start/end of a feature.
    case feature

    /// Executes before/after each scenario (pickle).
    case scenario

    /// Executes before/after each step within a scenario.
    case step
}

/// A lifecycle hook that executes at a specified scope during test execution.
///
/// Hooks can optionally be filtered by tag expression, executing only when
/// the current scope's tags satisfy the filter.
///
/// ```swift
/// let hook = Hook(
///     scope: .scenario,
///     tagFilter: try TagFilter("@smoke"),
///     handler: { print("Before smoke scenario") }
/// )
/// ```
public struct Hook: Sendable {
    /// The scope at which this hook executes.
    public let scope: HookScope

    /// An optional tag filter. The hook only executes when the current
    /// scope's tags satisfy this filter.
    public let tagFilter: TagFilter?

    /// The handler closure to execute.
    public let handler: @Sendable () async throws -> Void

    /// Creates a new hook.
    ///
    /// - Parameters:
    ///   - scope: The scope at which this hook executes.
    ///   - tagFilter: An optional tag filter for conditional execution.
    ///   - handler: The closure to execute.
    public init(
        scope: HookScope,
        tagFilter: TagFilter? = nil,
        handler: @escaping @Sendable () async throws -> Void
    ) {
        self.scope = scope
        self.tagFilter = tagFilter
        self.handler = handler
    }
}

/// A registry of before/after hooks organized by scope.
///
/// The `HookRegistry` stores lifecycle hooks and executes them in registration
/// order. Before hooks execute in forward order; after hooks execute in
/// reverse order (LIFO) to ensure proper cleanup.
///
/// ```swift
/// var registry = HookRegistry()
/// registry.addBefore(Hook(scope: .scenario) { print("Before scenario") })
/// registry.addAfter(Hook(scope: .scenario) { print("After scenario") })
///
/// try await registry.executeBefore(scope: .scenario, tags: ["@smoke"])
/// // ... run scenario ...
/// try await registry.executeAfter(scope: .scenario, tags: ["@smoke"])
/// ```
public struct HookRegistry: Sendable {
    /// The registered before hooks in registration order.
    public private(set) var beforeHooks: [Hook]

    /// The registered after hooks in registration order.
    public private(set) var afterHooks: [Hook]

    /// Creates a new hook registry.
    ///
    /// - Parameters:
    ///   - beforeHooks: Initial before hooks. Defaults to empty.
    ///   - afterHooks: Initial after hooks. Defaults to empty.
    public init(beforeHooks: [Hook] = [], afterHooks: [Hook] = []) {
        self.beforeHooks = beforeHooks
        self.afterHooks = afterHooks
    }

    /// Registers a before hook.
    ///
    /// - Parameter hook: The hook to execute before the given scope.
    public mutating func addBefore(_ hook: Hook) {
        beforeHooks.append(hook)
    }

    /// Registers an after hook.
    ///
    /// - Parameter hook: The hook to execute after the given scope.
    public mutating func addAfter(_ hook: Hook) {
        afterHooks.append(hook)
    }

    /// Executes all before hooks matching the given scope and tags.
    ///
    /// Hooks execute in registration order (FIFO). A hook with a tag filter
    /// is skipped if the tags don't satisfy the filter.
    ///
    /// - Parameters:
    ///   - scope: The scope to execute hooks for.
    ///   - tags: The current tags to evaluate hook filters against.
    /// - Throws: Any error thrown by a hook handler.
    public func executeBefore(scope: HookScope, tags: [String]) async throws {
        for hook in beforeHooks where hook.scope == scope {
            if let filter = hook.tagFilter, !filter.matches(tags: tags) {
                continue
            }
            try await hook.handler()
        }
    }

    /// Executes all after hooks matching the given scope and tags.
    ///
    /// Hooks execute in reverse registration order (LIFO) to ensure
    /// proper cleanup. A hook with a tag filter is skipped if the tags
    /// don't satisfy the filter. All hooks execute even if earlier ones throw.
    ///
    /// - Parameters:
    ///   - scope: The scope to execute hooks for.
    ///   - tags: The current tags to evaluate hook filters against.
    /// - Throws: The first error thrown by any hook handler.
    public func executeAfter(scope: HookScope, tags: [String]) async throws {
        var firstError: (any Error)?
        for hook in afterHooks.reversed() where hook.scope == scope {
            if let filter = hook.tagFilter, !filter.matches(tags: tags) {
                continue
            }
            do {
                try await hook.handler()
            } catch {
                if firstError == nil {
                    firstError = error
                }
            }
        }
        if let error = firstError {
            throw error
        }
    }
}
