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

/// A cart item with product name, quantity, and unit price.
struct CartItem: Sendable {
    var product: String
    var quantity: Int
    var price: Double
}

/// A product catalog entry with name, price, and status.
struct CatalogEntry: Sendable {
    let name: String
    let price: Double
    let status: String
}

/// A mock authentication service for realistic demo step handlers.
///
/// This actor simulates an authentication backend with login validation,
/// session tracking, and navigation state. Step handlers interact with
/// it via `await` to demonstrate async step definitions.
actor MockAuthService {
    /// Known valid credentials (username → password).
    private let validCredentials: [String: String] = [
        "alice": "secret123",
        "bob": "password456"
    ]

    /// Whether the app has been launched.
    private(set) var isAppLaunched = false

    /// Whether the user is on the login page.
    private(set) var isOnLoginPage = false

    /// Whether the user is on the registration page.
    private(set) var isOnRegistrationPage = false

    /// The currently logged-in username, or `nil`.
    private(set) var loggedInUser: String?

    /// The last error message from a failed operation.
    private(set) var lastError: String?

    /// The current page being displayed.
    private(set) var currentPage: String?

    /// Whether registration was successful.
    private(set) var registrationComplete = false

    /// Simulates launching the app.
    func launchApp() {
        isAppLaunched = true
        currentPage = "home"
    }

    /// Navigates to the login page.
    func navigateToLoginPage() {
        isOnLoginPage = true
        currentPage = "login"
    }

    /// Navigates to the registration page.
    func navigateToRegistrationPage() {
        isOnRegistrationPage = true
        currentPage = "registration"
    }

    /// Attempts to log in with the given credentials.
    ///
    /// - Parameters:
    ///   - username: The username.
    ///   - password: The password.
    /// - Returns: `true` if login succeeded.
    @discardableResult
    func login(username: String, password: String) -> Bool {
        if validCredentials[username] == password {
            loggedInUser = username
            lastError = nil
            currentPage = "dashboard"
            return true
        } else {
            loggedInUser = nil
            lastError = "Invalid username or password"
            currentPage = "login"
            return false
        }
    }

    /// Simulates registration with form data.
    func register(email: String, password: String, username: String) {
        if email.isEmpty {
            lastError = "Email is required"
        } else if password.count < 6 {
            lastError = "Password is too short"
        } else if username.count < 2 {
            lastError = "Username is too short"
        } else {
            registrationComplete = true
            lastError = nil
            currentPage = "welcome"
        }
    }

    /// Navigates to a named page.
    func navigate(to page: String) {
        currentPage = page
    }

    /// Resets all state.
    func reset() {
        isAppLaunched = false
        isOnLoginPage = false
        isOnRegistrationPage = false
        loggedInUser = nil
        lastError = nil
        currentPage = nil
        registrationComplete = false
        storeOpen = false
        catalogLoaded = false
        cart = []
        appliedDiscount = nil
        selectedCurrency = "USD"
        lastReview = nil
        orderConfirmed = false
        lastStatusFilter = nil
    }

    // MARK: - E-Commerce State

    /// Whether the store has been opened.
    private(set) var storeOpen = false

    /// Whether the product catalog has been loaded.
    private(set) var catalogLoaded = false

    /// The items currently in the cart.
    private(set) var cart: [CartItem] = []

    /// The applied discount code, if any.
    private(set) var appliedDiscount: String?

    /// The selected currency code (default "USD").
    private(set) var selectedCurrency = "USD"

    /// The last submitted review, if any.
    private(set) var lastReview: (product: String, body: String)?

    /// Whether the last order was confirmed.
    private(set) var orderConfirmed = false

    /// The last product status filter applied.
    private(set) var lastStatusFilter: String?

    /// The product catalog.
    let catalog: [CatalogEntry] = [
        CatalogEntry(name: "Wireless Mouse", price: 29.99, status: "active"),
        CatalogEntry(name: "USB Keyboard", price: 59.99, status: "active"),
        CatalogEntry(name: "Laptop Stand", price: 49.99, status: "active"),
        CatalogEntry(name: "HDMI Cable", price: 14.99, status: "active")
    ]

    // MARK: - E-Commerce Actions

    /// Opens the store.
    func openStore() {
        storeOpen = true
    }

    /// Loads the product catalog.
    func loadCatalog() {
        catalogLoaded = true
    }

    /// Adds a product to the cart by name with quantity 1.
    func addToCart(product: String) {
        let price = catalog.first(where: { $0.name == product })?.price ?? 0.0
        if let index = cart.firstIndex(where: { $0.product == product }) {
            cart[index].quantity += 1
        } else {
            cart.append(CartItem(product: product, quantity: 1, price: price))
        }
    }

    /// Adds a product to the cart with a specific price.
    func addToCart(product: String, price: Double) {
        if let index = cart.firstIndex(where: { $0.product == product }) {
            cart[index].quantity += 1
        } else {
            cart.append(CartItem(product: product, quantity: 1, price: price))
        }
    }

    /// Adds multiple items to the cart.
    func addToCart(product: String, quantity: Int) {
        let price = catalog.first(where: { $0.name == product })?.price ?? 0.0
        if let index = cart.firstIndex(where: { $0.product == product }) {
            cart[index].quantity += quantity
        } else {
            cart.append(CartItem(product: product, quantity: quantity, price: price))
        }
    }

    /// The total number of items in the cart (sum of quantities).
    var cartItemCount: Int {
        cart.reduce(0) { $0 + $1.quantity }
    }

    /// The cart subtotal before discounts.
    var cartSubtotal: Double {
        cart.reduce(0.0) { $0 + Double($1.quantity) * $1.price }
    }

    /// The cart total after discounts.
    var cartTotal: Double {
        var total = cartSubtotal
        if appliedDiscount == "SAVE20" {
            total *= 0.8
        }
        // Round to 2 decimal places
        return (total * 100).rounded() / 100
    }

    /// Applies a discount code.
    func applyDiscount(code: String) {
        appliedDiscount = code
    }

    /// Selects a display currency.
    func selectCurrency(_ code: String) {
        selectedCurrency = code
    }

    /// Submits a product review.
    func submitReview(product: String, body: String) {
        lastReview = (product: product, body: body)
    }

    /// Filters products by status.
    func filterByStatus(_ status: String) {
        lastStatusFilter = status
    }

    /// Products matching the current status filter.
    var filteredProducts: [CatalogEntry] {
        guard let filter = lastStatusFilter else { return catalog }
        return catalog.filter { $0.status == filter }
    }

    /// Attempts checkout. Requires authentication and non-empty cart.
    func checkout() -> Bool {
        guard loggedInUser != nil else {
            lastError = "Authentication required"
            currentPage = "login"
            return false
        }
        guard !cart.isEmpty else {
            lastError = "Cart is empty"
            return false
        }
        orderConfirmed = true
        currentPage = "confirmation"
        return true
    }
}
