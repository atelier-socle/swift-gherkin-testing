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

/// Specifies a report format and optional output path for auto-generated reports.
///
/// Use `ReportFormat` with the `@Feature(reports:)` parameter to automatically
/// write test reports after feature execution. Each format produces a file at
/// either a default path or a custom path you provide.
///
/// Default output directory: `/tmp/swift-gherkin-testing/reports/`
/// Default filename: `{StructName}.{ext}` (e.g. `LoginFeature.html`)
///
/// ```swift
/// // HTML and JUnit XML with default paths
/// @Feature(source: .file("login.feature"), reports: [.html, .junitXML])
///
/// // Custom output path
/// @Feature(source: .file("login.feature"), reports: [.html("reports/login.html")])
///
/// // All formats
/// @Feature(source: .file("login.feature"), reports: ReportFormat.all)
/// ```
public struct ReportFormat: Sendable {
    /// The kind of report to generate.
    public let kind: Kind

    /// An optional custom output path. When `nil`, the default path is used.
    public let customPath: String?

    /// The supported report output kinds.
    public enum Kind: Sendable {
        /// Standalone HTML report.
        case html
        /// Cucumber JSON report.
        case json
        /// JUnit XML report.
        case junitXML
    }

    /// Standalone HTML report with default output path.
    public static var html: ReportFormat { ReportFormat(kind: .html, customPath: nil) }

    /// Standalone HTML report with a custom output path.
    ///
    /// - Parameter path: The file path to write the HTML report to.
    public static func html(_ path: String) -> ReportFormat { ReportFormat(kind: .html, customPath: path) }

    /// Cucumber JSON report with default output path.
    public static var json: ReportFormat { ReportFormat(kind: .json, customPath: nil) }

    /// Cucumber JSON report with a custom output path.
    ///
    /// - Parameter path: The file path to write the JSON report to.
    public static func json(_ path: String) -> ReportFormat { ReportFormat(kind: .json, customPath: path) }

    /// JUnit XML report with default output path.
    public static var junitXML: ReportFormat { ReportFormat(kind: .junitXML, customPath: nil) }

    /// JUnit XML report with a custom output path.
    ///
    /// - Parameter path: The file path to write the XML report to.
    public static func junitXML(_ path: String) -> ReportFormat { ReportFormat(kind: .junitXML, customPath: path) }

    /// All report formats with default output paths.
    public static let all: [ReportFormat] = [.html, .json, .junitXML]
}
