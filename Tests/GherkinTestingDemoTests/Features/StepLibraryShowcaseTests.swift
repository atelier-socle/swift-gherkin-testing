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
import GherkinTesting
import Testing

// MARK: - Step Library Composition Showcase
//
// This @Feature struct is intentionally EMPTY — every step definition comes
// from the three composed step libraries. This demonstrates that @StepLibrary
// enables zero-code features: just declare the source and compose libraries.

@Feature(
    source: .file("Fixtures/en/step-libraries-showcase.feature"),
    reports: [.html],
    stepLibraries: [AuthenticationSteps.self, NavigationSteps.self, ValidationSteps.self]
)
struct StepLibraryShowcase {}
