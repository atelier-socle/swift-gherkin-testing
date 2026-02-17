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

@Suite("ExampleRepresentable Tests")
struct ExampleRepresentableTests {

    // MARK: - String

    @Test("String from example")
    func stringConversion() {
        #expect(String.fromExample("hello") == "hello")
        #expect(String.fromExample("") == "")
        #expect(String.fromExample("  spaces  ") == "  spaces  ")
    }

    // MARK: - Int

    @Test("Int from example")
    func intConversion() {
        #expect(Int.fromExample("42") == 42)
        #expect(Int.fromExample("-7") == -7)
        #expect(Int.fromExample("0") == 0)
    }

    @Test("Int from invalid example returns nil")
    func intInvalid() {
        #expect(Int.fromExample("abc") == nil)
        #expect(Int.fromExample("3.14") == nil)
        #expect(Int.fromExample("") == nil)
    }

    // MARK: - Double

    @Test("Double from example")
    func doubleConversion() {
        #expect(Double.fromExample("3.14") == 3.14)
        #expect(Double.fromExample("-2.5") == -2.5)
        #expect(Double.fromExample("42") == 42.0)
        #expect(Double.fromExample("0") == 0.0)
    }

    @Test("Double from invalid example returns nil")
    func doubleInvalid() {
        #expect(Double.fromExample("abc") == nil)
        #expect(Double.fromExample("") == nil)
    }

    // MARK: - Bool

    @Test("Bool from true values")
    func boolTrue() {
        #expect(Bool.fromExample("true") == true)
        #expect(Bool.fromExample("True") == true)
        #expect(Bool.fromExample("TRUE") == true)
        #expect(Bool.fromExample("yes") == true)
        #expect(Bool.fromExample("Yes") == true)
        #expect(Bool.fromExample("1") == true)
    }

    @Test("Bool from false values")
    func boolFalse() {
        #expect(Bool.fromExample("false") == false)
        #expect(Bool.fromExample("False") == false)
        #expect(Bool.fromExample("FALSE") == false)
        #expect(Bool.fromExample("no") == false)
        #expect(Bool.fromExample("No") == false)
        #expect(Bool.fromExample("0") == false)
    }

    @Test("Bool from invalid example returns nil")
    func boolInvalid() {
        #expect(Bool.fromExample("abc") == nil)
        #expect(Bool.fromExample("") == nil)
        #expect(Bool.fromExample("2") == nil)
    }

    // MARK: - Optional

    @Test("Optional String from example")
    func optionalString() {
        let result: String?? = String?.fromExample("hello")
        #expect(result == .some("hello"))
    }

    @Test("Optional empty string becomes nil")
    func optionalEmpty() {
        let result: String?? = String?.fromExample("")
        #expect(result == .some(nil))
    }

    @Test("Optional Int from valid string")
    func optionalInt() {
        let result: Int?? = Int?.fromExample("42")
        #expect(result == .some(42))
    }

    @Test("Optional Int from invalid string returns nil")
    func optionalIntInvalid() {
        let result: Int?? = Int?.fromExample("abc")
        #expect(result == nil)
    }
}
