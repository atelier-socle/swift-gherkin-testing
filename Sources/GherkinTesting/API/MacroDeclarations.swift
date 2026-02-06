// MacroDeclarations.swift
// GherkinTesting
//
// Copyright © 2026 Atelier Socle. MIT License.

// MARK: - Feature Macro

/// Declares a Gherkin feature from a `.feature` source.
///
/// `@Feature` generates a Swift Testing `@Suite` with `@Test` methods for each
/// scenario in the feature. The type must be a `struct` with step definitions
/// implemented as methods annotated with `@Given`, `@When`, `@Then`, etc.
///
/// For `.inline(...)` sources, scenario names are extracted at compile time and
/// each scenario gets its own `@Test` method. For `.file(...)` sources, a single
/// `@Test` method is generated that parses the file at runtime.
///
/// ```swift
/// @Feature(source: .inline("""
///     Feature: Login
///       Scenario: Successful login
///         Given the user is on the login page
///         When they enter valid credentials
///         Then they should see the dashboard
///     """))
/// struct LoginFeature {
///     @Given("the user is on the login page")
///     mutating func onLoginPage() { }
///
///     @When("they enter valid credentials")
///     mutating func enterCredentials() { }
///
///     @Then("they should see the dashboard")
///     mutating func seeDashboard() { }
/// }
/// ```
@attached(extension, conformances: GherkinFeature)
@attached(member, names: named(__stepDefinitions), named(__hooks))
@attached(peer, names: suffixed(__GherkinTests))
public macro Feature(
    source: FeatureSource,
    stepLibraries: [any StepLibrary.Type] = []
) = #externalMacro(
    module: "GherkinTestingMacros",
    type: "FeatureMacro"
)

// MARK: - Step Macros

/// Declares a step definition for `Given` (context) steps.
///
/// The expression can be a plain string (exact match) or contain
/// Cucumber placeholders like `{string}`, `{int}`, `{float}`, `{word}`, `{}`.
///
/// ```swift
/// @Given("the user is logged in")
/// mutating func userLoggedIn() { }
///
/// @Given("there are {int} items in the cart")
/// mutating func itemsInCart(count: String) { }
/// ```
@attached(peer, names: prefixed(__stepDef_))
public macro Given(_ expression: String) = #externalMacro(
    module: "GherkinTestingMacros",
    type: "GivenMacro"
)

/// Declares a step definition for `When` (action) steps.
///
/// ```swift
/// @When("the user clicks the login button")
/// mutating func clickLogin() { }
/// ```
@attached(peer, names: prefixed(__stepDef_))
public macro When(_ expression: String) = #externalMacro(
    module: "GherkinTestingMacros",
    type: "WhenMacro"
)

/// Declares a step definition for `Then` (outcome) steps.
///
/// ```swift
/// @Then("the user should see the dashboard")
/// mutating func seeDashboard() { }
/// ```
@attached(peer, names: prefixed(__stepDef_))
public macro Then(_ expression: String) = #externalMacro(
    module: "GherkinTestingMacros",
    type: "ThenMacro"
)

/// Declares a step definition for `And` (conjunction) steps.
///
/// ```swift
/// @And("the cart is empty")
/// mutating func cartEmpty() { }
/// ```
@attached(peer, names: prefixed(__stepDef_))
public macro And(_ expression: String) = #externalMacro(
    module: "GherkinTestingMacros",
    type: "AndMacro"
)

/// Declares a step definition for `But` (conjunction) steps.
///
/// ```swift
/// @But("the user is not an admin")
/// mutating func notAdmin() { }
/// ```
@attached(peer, names: prefixed(__stepDef_))
public macro But(_ expression: String) = #externalMacro(
    module: "GherkinTestingMacros",
    type: "ButMacro"
)

// MARK: - Hook Macros

/// Declares a before hook that runs before the specified scope.
///
/// Hooks must be `static` functions. The scope defaults to `.scenario` if not specified.
///
/// ```swift
/// @Before(.scenario)
/// static func setUp() async throws { }
///
/// @Before(.feature, tags: "@smoke")
/// static func setupSmoke() async throws { }
/// ```
@attached(peer, names: prefixed(__hook_))
public macro Before(_ scope: HookScope = .scenario, tags: String? = nil, order: Int = 0) = #externalMacro(
    module: "GherkinTestingMacros",
    type: "BeforeMacro"
)

/// Declares an after hook that runs after the specified scope.
///
/// Hooks must be `static` functions. After hooks always run, even if the
/// scenario or step fails.
///
/// ```swift
/// @After(.scenario)
/// static func tearDown() async throws { }
/// ```
@attached(peer, names: prefixed(__hook_))
public macro After(_ scope: HookScope = .scenario, tags: String? = nil, order: Int = 0) = #externalMacro(
    module: "GherkinTestingMacros",
    type: "AfterMacro"
)

// MARK: - StepLibrary Macro

/// Declares a reusable step definition library.
///
/// `@StepLibrary` generates `StepLibrary` protocol conformance and a
/// `__stepDefinitions` static property that collects all step definitions.
///
/// ```swift
/// @StepLibrary
/// struct SharedAuthSteps {
///     @Given("the user is logged in")
///     mutating func loggedIn() { }
/// }
/// ```
@attached(member, names: named(__stepDefinitions))
@attached(extension, conformances: StepLibrary)
public macro StepLibrary() = #externalMacro(
    module: "GherkinTestingMacros",
    type: "StepLibraryMacro"
)
