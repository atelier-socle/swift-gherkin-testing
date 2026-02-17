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

/// An argument attached to a Gherkin step (DataTable or DocString).
///
/// Bridges ``PickleStepArgument`` (compiler internal) to a public execution type
/// that step handlers receive. DataTable arguments are passed as ``DataTable``
/// values; DocString arguments are passed as plain `String` content.
///
/// ```swift
/// @Given("the following users exist:")
/// func usersExist(table: DataTable) async throws {
///     let headers = table.headers
///     let rows = table.asDictionaries
/// }
///
/// @When("the API receives the payload:")
/// func apiPayload(body: String) async throws {
///     // body is the DocString content
/// }
/// ```
public enum StepArgument: Sendable, Equatable {
    /// A data table argument.
    case dataTable(DataTable)

    /// A doc string argument (just the content string).
    case docString(String)

    /// The data table, if this is a `.dataTable` argument.
    ///
    /// - Returns: The ``DataTable`` value, or `nil` if this is a doc string.
    public var dataTable: DataTable? {
        if case .dataTable(let table) = self {
            return table
        }
        return nil
    }

    /// The doc string content, if this is a `.docString` argument.
    ///
    /// - Returns: The string content, or `nil` if this is a data table.
    public var docString: String? {
        if case .docString(let content) = self {
            return content
        }
        return nil
    }

    /// Creates a `StepArgument` from a ``PickleStepArgument``, if present.
    ///
    /// - Parameter pickleArg: The pickle step argument to convert.
    /// - Returns: A `StepArgument`, or `nil` if the input is `nil`.
    public init?(from pickleArg: PickleStepArgument?) {
        guard let pickleArg else { return nil }
        switch pickleArg {
        case .dataTable(let table):
            self = .dataTable(table)
        case .docString(let doc):
            self = .docString(doc.content)
        }
    }
}
