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

// MARK: - Showcase Feature: Comprehensive Demo of All Framework Capabilities
//
// This file demonstrates every major feature of swift-gherkin-testing:
//
// 1. @Feature with .file() source (runtime parsing from Bundle.module)
// 2. reports: parameter for auto-generated HTML, JSON, JUnit XML reports
// 3. stepLibraries: for composable step definitions (AuthenticationSteps)
// 4. gherkinConfiguration with custom parameter types ({status}, {currency})
// 5. @Given/@When/@Then/@And/@But step macros
// 6. @Before/@After hooks at feature and scenario scope
// 7. Cucumber Expressions: {string}, {int}, {float}, {status}, {currency}
// 8. DataTable parameter in step handlers
// 9. DocString parameter in step handlers
// 10. Mixed captured args + DataTable
// 11. #expect assertions in handlers
// 12. Background, Rule, Scenario Outline with Examples
// 13. Tag filtering and tag-based hooks
// 14. ~100 examples in a Scenario Outline (performance)

@Feature(
    source: .file("Fixtures/en/showcase.feature"),
    reports: [.html, .json, .junitXML]
)
struct ShowcaseFeature {
    let shop = MockAuthService()

    // MARK: - Custom Parameter Types Configuration

    static var gherkinConfiguration: GherkinConfiguration {
        GherkinConfiguration(
            parameterTypes: [
                .type("status", matching: "active|inactive|pending|banned"),
                .type("currency", matching: "USD|EUR|GBP|JPY")
            ]
        )
    }

    // MARK: - Feature-level Hooks

    @Before(.feature)
    static func featureSetUp() async throws {
        await Task.yield()
    }

    @After(.feature)
    static func featureTearDown() async throws {
        await Task.yield()
    }

    // MARK: - Scenario-level Hooks

    @Before(.scenario)
    static func scenarioSetUp() async throws {
        await Task.yield()
    }

    @After(.scenario)
    static func scenarioTearDown() async throws {
        await Task.yield()
    }

    // MARK: - Background Steps
    // Background runs before every scenario — reset state for isolation

    @Given("the store is open")
    func storeOpen() async throws {
        await shop.reset()
        await shop.openStore()
        let open = await shop.storeOpen
        #expect(open)
    }

    @And("the product catalog is loaded")
    func catalogLoaded() async throws {
        await shop.loadCatalog()
        let loaded = await shop.catalogLoaded
        #expect(loaded)
    }

    // MARK: - Catalog / Browsing Steps

    @When("the customer views the catalog")
    func viewCatalog() async throws {
        await shop.loadCatalog()
    }

    @Then("they should see at least {int} products")
    func seeProducts(count: String) async throws {
        let expected = Int(count) ?? 0
        let products = await shop.filteredProducts
        #expect(products.count >= expected)
    }

    @Then("the following products should be available:")
    func productsAvailable(table: DataTable) async throws {
        let catalog = shop.catalog
        let dicts = table.asDictionaries
        for dict in dicts {
            let name = dict["name"] ?? ""
            let price = dict["price"] ?? ""
            let status = dict["status"] ?? ""
            let found = catalog.first(where: { $0.name == name })
            #expect(found != nil, "Product '\(name)' should exist in catalog")
            if let found = found {
                #expect(String(found.price) == price, "Price of '\(name)' should be \(price)")
                #expect(found.status == status, "Status of '\(name)' should be \(status)")
            }
        }
    }

    // MARK: - Authentication Steps

    @Given("the customer is logged in as {string}")
    func loggedIn(username: String) async throws {
        await shop.launchApp()
        let password = username == "alice" ? "secret123" : "password456"
        await shop.login(username: username, password: password)
        let user = await shop.loggedInUser
        #expect(user == username)
    }

    @Given("the customer navigates to login")
    func navigateToLogin() async throws {
        await shop.launchApp()
        await shop.navigateToLoginPage()
    }

    @When("they attempt login with {string} and {string}")
    func attemptLogin(username: String, password: String) async throws {
        await shop.login(username: username, password: password)
    }

    @Then("the login result should be {string}")
    func loginResult(result: String) async throws {
        if result == "success" {
            let user = await shop.loggedInUser
            #expect(user != nil)
        } else {
            let error = await shop.lastError
            #expect(error != nil)
        }
    }

    // MARK: - Cart Steps

    @When("they add {string} to the cart")
    func addToCart(product: String) async throws {
        await shop.addToCart(product: product)
    }

    @Then("the cart should contain {int} items")
    func cartContains(count: String) async throws {
        let expected = Int(count) ?? 0
        let actual = await shop.cartItemCount
        #expect(actual == expected)
    }

    @But("the cart total should not be {float}")
    func cartTotalNotZero(amount: String) async throws {
        let excluded = Double(amount) ?? 0.0
        let total = await shop.cartTotal
        #expect(total != excluded)
    }

    @And("the cart contains {string} at {float}")
    func cartContainsProduct(product: String, price: String) async throws {
        let priceVal = Double(price) ?? 0.0
        await shop.addToCart(product: product, price: priceVal)
    }

    @When("they add {int} items to the cart:")
    func bulkAddToCart(count: String, table: DataTable) async throws {
        let dicts = table.asDictionaries
        for dict in dicts {
            let product = dict["product"] ?? ""
            let quantity = Int(dict["quantity"] ?? "1") ?? 1
            await shop.addToCart(product: product, quantity: quantity)
        }
    }

    // MARK: - Pricing / Discount Steps

    @When("they apply the discount code {string}")
    func applyDiscount(code: String) async throws {
        await shop.applyDiscount(code: code)
    }

    @Then("the cart total should be {float}")
    func cartTotal(total: String) async throws {
        let expected = Double(total) ?? 0.0
        let actual = await shop.cartTotal
        #expect(actual == expected)
    }

    // MARK: - DocString Step: Product Review

    @When("they submit a review for {string} with:")
    func submitReview(product: String, body: String) async throws {
        await shop.submitReview(product: product, body: body)
    }

    @Then("the review should be submitted successfully")
    func reviewSubmitted() async throws {
        let review = await shop.lastReview
        #expect(review != nil)
    }

    // MARK: - Custom Parameter Type Steps: {status}, {currency}

    @When("they filter products by status {status}")
    func filterByStatus(status: String) async throws {
        await shop.filterByStatus(status)
    }

    @When("they select currency {currency}")
    func selectCurrency(currency: String) async throws {
        await shop.selectCurrency(currency)
    }

    @Then("the displayed currency should be {currency}")
    func displayedCurrency(currency: String) async throws {
        let actual = await shop.selectedCurrency
        #expect(actual == currency)
    }

    // MARK: - Checkout Steps (Rule: Checkout requires authentication)

    @When("a guest tries to checkout")
    func guestCheckout() async throws {
        let result = await shop.checkout()
        #expect(!result)
    }

    @Then("they should be redirected to login")
    func redirectedToLogin() async throws {
        let page = await shop.currentPage
        #expect(page == "login")
    }

    @When("they proceed to checkout")
    func proceedToCheckout() async throws {
        _ = await shop.checkout()
    }

    @Then("the order should be confirmed")
    func orderConfirmed() async throws {
        let confirmed = await shop.orderConfirmed
        #expect(confirmed)
    }

    @Then("they should see the error {string}")
    func seeError(message: String) async throws {
        let error = await shop.lastError
        #expect(error == message)
    }

    // MARK: - Large Scenario Outline Steps (product + price)

    @When("they add {string} at {float} to the cart")
    func addProductAtPrice(product: String, price: String) async throws {
        let priceVal = Double(price) ?? 0.0
        await shop.addToCart(product: product, price: priceVal)
    }

    @Then("the item {string} should be in the cart at {float}")
    func itemInCart(product: String, price: String) async throws {
        let cart = await shop.cart
        let found = cart.first(where: { $0.product == product })
        #expect(found != nil, "'\(product)' should be in cart")
        if let found = found {
            let expectedPrice = Double(price) ?? 0.0
            #expect(found.price == expectedPrice)
        }
    }
}
