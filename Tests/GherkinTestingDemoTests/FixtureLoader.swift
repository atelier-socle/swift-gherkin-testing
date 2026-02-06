// FixtureLoader.swift
// GherkinTestingDemoTests
//
// Copyright © 2026 Atelier Socle. MIT License.

import Foundation

/// Loads a .feature fixture file from the demo test bundle.
///
/// - Parameter relativePath: Path relative to the Fixtures directory (e.g. "en/login.feature").
/// - Returns: The file content as a String.
/// - Throws: If the fixture cannot be found or read.
func loadFixture(_ relativePath: String) throws -> String {
    let components = relativePath.split(separator: "/")
    let directory = components.dropLast().joined(separator: "/")
    let filename = String(components.last ?? "")
    let name = filename.split(separator: ".").first.map(String.init) ?? filename
    let ext = filename.split(separator: ".").last.map(String.init) ?? "feature"

    guard let url = Bundle.module.url(
        forResource: name,
        withExtension: ext,
        subdirectory: "Fixtures/\(directory)"
    ) else {
        throw FixtureError.notFound(relativePath)
    }
    return try String(contentsOf: url, encoding: .utf8)
}

enum FixtureError: Error {
    case notFound(String)
}
