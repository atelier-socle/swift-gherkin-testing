@auth
Feature: Registration
  New users can create an account.

  Scenario: Successful registration
    Given the user is on the registration page
    When they fill in the registration form with valid data
    And they submit the form
    Then their account is created
    And they are redirected to the welcome page

  Scenario Outline: Invalid registration
    Given the user is on the registration page
    When they fill in the <field> with "<value>"
    Then they should see the validation error "<error>"

    Examples:
      | field    | value | error                    |
      | email    |       | Email is required        |
      | password | 123   | Password is too short    |
      | username | a     | Username is too short    |
