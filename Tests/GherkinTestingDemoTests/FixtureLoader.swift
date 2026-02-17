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

    guard
        let url = Bundle.module.url(
            forResource: name,
            withExtension: ext,
            subdirectory: "Fixtures/\(directory)"
        )
    else {
        throw FixtureError.notFound(relativePath)
    }
    return try String(contentsOf: url, encoding: .utf8)
}

enum FixtureError: Error {
    case notFound(String)
}
