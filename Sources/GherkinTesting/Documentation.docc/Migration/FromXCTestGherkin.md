# Migrating from XCTest Gherkin Frameworks

Transition from XCTest-based BDD frameworks to Gherkin Testing.

## Overview

If you are using XCTest-based Gherkin frameworks (XCTest-Gherkin, CucumberSwift, or custom `XCTestCase` solutions), this guide outlines the key differences and migration path.

### Architecture Comparison

| Aspect | XCTest Gherkin | Gherkin Testing |
|--------|---------------|-----------------|
| Test class | `XCTestCase` subclass | `@Feature` struct |
| Step registration | Method overrides / runtime lookup | `@Given`/`@When`/`@Then` macros |
| Step matching | Runtime regex | Compile-time detection + Cucumber Expressions |
| Assertions | `XCTAssert*` | `#expect` / `#require` (Swift Testing) |
| State | Mutable class properties | Value-type struct + actors |
| Hooks | `setUp()` / `tearDown()` overrides | `@Before` / `@After` with scopes |
| Concurrency | Main thread / serial | `async throws` / full concurrency |
| Thread safety | Manual (`NSLock`, queues) | `Sendable` + `actor` (compiler-enforced) |
| Tag filtering | XCTest test plans | ``TagFilter`` boolean expressions |
| Reports | Test attachments | ``GherkinReporter`` (HTML, JSON, JUnit XML) |

### Step-by-Step Migration

**1. Replace the test class with a struct:**

```swift
// Before (XCTest)
class LoginTests: XCTestCase { ... }

// After (Gherkin Testing)
@Feature(source: .file("Fixtures/en/login.feature"))
struct LoginFeature { ... }
```

**2. Replace step registration with macros:**

```swift
// Before: runtime registration
step("the user is on the login page") { ... }

// After: compile-time macro
@Given("the user is on the login page")
func onLoginPage() async throws { ... }
```

**3. Replace assertions:**

```swift
// Before
XCTAssertEqual(page, "dashboard")
XCTAssertNotNil(user)

// After
#expect(page == "dashboard")
let user = try #require(user)
```

**4. Replace setUp/tearDown with hooks:**

```swift
// Before
override func setUp() { ... }
override func tearDown() { ... }

// After
@Before(.scenario)
static func setUp() async throws { ... }

@After(.scenario)
static func tearDown() async throws { ... }
```

**5. Replace mutable state with actors:**

```swift
// Before: mutable class properties
var loggedIn = false

// After: actor-based state
let auth = MockAuthService()  // actor
```

### Advantages of Gherkin Testing

- **Compile-time safety**: macro expansion catches step expression errors at build time
- **Swift Concurrency**: native `async`/`await` with compiler-enforced `Sendable`
- **Swift Testing integration**: `@Suite`/`@Test` generated under the hood, full Xcode test navigator support
- **Zero runtime dependencies**: no framework code shipped with your app
- **Cucumber Expressions**: readable `{string}`, `{int}` placeholders instead of raw regex
- **Step libraries**: composable `@StepLibrary` modules for reuse across features
- **Built-in reporters**: HTML, Cucumber JSON, JUnit XML without additional tools

## See Also

- <doc:GettingStarted>
- <doc:StepDefinitions>
