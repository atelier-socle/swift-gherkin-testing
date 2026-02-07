# Step Library Composition Showcase
# All steps are handled by AuthenticationSteps, NavigationSteps, and ValidationSteps.
# The @Feature struct is empty — zero step definitions, 100% composed from libraries.
#
# Note: Each step library creates its own state per step invocation via retyped(),
# so scenarios are designed around stateless or self-contained steps.

@step-libraries
Feature: User Application Flows
  Demonstrates composing step libraries for authentication, navigation, and validation.

  Background:
    Given the app is launched

  # --- AuthenticationSteps: login page navigation ---

  @auth @smoke
  Scenario: Navigate to login page
    Given the user is on the login page

  # --- AuthenticationSteps: registration page navigation ---

  @auth @registration
  Scenario: Navigate to registration page
    Given the user is on the registration page

  # --- AuthenticationSteps: form submission ---

  @auth
  Scenario: Submit a form
    And they submit the form

  # --- NavigationSteps: logged-in user context ---

  @navigation
  Scenario: User is logged in
    Given the user is logged in

  # --- ValidationSteps: field validation flows ---

  @validation
  Scenario: Validate email field content
    Given the email field contains "alice@example.com"
    Then the field "email" should be valid

  @validation
  Scenario: Validate username field content
    Given the username field contains "bob"
    Then the field "username" should be valid

  @validation
  Scenario: Detect invalid field
    Given the password field contains ""
    Then the field "password" should be invalid

  # --- Cross-library: AuthenticationSteps + ValidationSteps ---

  @auth @validation
  Scenario: Login page with field validation
    Given the user is on the login page
    And the email field contains "test@example.com"
    Then the field "email" should be valid

  # --- Scenario Outline: field validation with various inputs (ValidationSteps) ---

  @validation @outline
  Scenario Outline: Validate form fields
    Given the <field> field contains "<value>"
    Then the field "<field>" should be <validity>

    Examples:
      | field    | value             | validity |
      | email    | alice@example.com | valid    |
      | email    | bob@test.org      | valid    |
      | username | alice             | valid    |
      | username | bob               | valid    |
      | password | secret123         | valid    |
      | password |                   | invalid  |
