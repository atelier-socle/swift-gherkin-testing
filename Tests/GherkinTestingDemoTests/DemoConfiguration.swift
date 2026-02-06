// DemoConfiguration.swift
// GherkinTestingDemoTests
//
// Copyright © 2026 Atelier Socle. MIT License.

import GherkinTesting

/// Demonstrates GherkinConfiguration with various options.
enum DemoConfiguration {
    /// Standard configuration with all reporters.
    static func standard() -> GherkinConfiguration {
        GherkinConfiguration(
            reporters: [
                CucumberJSONReporter(),
                JUnitXMLReporter(),
                HTMLReporter()
            ]
        )
    }

    /// Dry-run configuration for validation without execution.
    static func dryRun() -> GherkinConfiguration {
        GherkinConfiguration(dryRun: true)
    }

    /// Configuration with tag filter.
    static func smokeOnly() throws -> GherkinConfiguration {
        GherkinConfiguration(tagFilter: try TagFilter("@smoke"))
    }
}
