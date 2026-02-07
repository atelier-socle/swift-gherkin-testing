# Migrating from XCTest Gherkin Frameworks

Transition from XCTest-based BDD frameworks to Gherkin Testing.

## Overview

If you are migrating from XCTest-based Gherkin/Cucumber frameworks (such as XCTest-Gherkin, CucumberSwift, or custom XCTestCase-based solutions), this guide helps you transition to Gherkin Testing's macro-based approach with Swift Testing.

<!-- TODO: Full article content covering:
- Key differences: XCTestCase subclass vs @Feature struct
- Step registration: method overrides vs @Given/@When/@Then macros
- Assertion migration: XCTAssert → #expect, XCTFail → Issue.record
- Async support: native async/throws vs completion handlers
- State management: class instance vs struct value semantics
- Hook migration: setUp/tearDown → @Before/@After
- Tag filtering: XCTest test plans vs TagFilter expressions
- Reporter migration: test attachments vs GherkinReporter
- Step-by-step migration checklist
-->
