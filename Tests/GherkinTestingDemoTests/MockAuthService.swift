// MockAuthService.swift
// GherkinTestingDemoTests
//
// Copyright © 2026 Atelier Socle. MIT License.

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
    }
}
