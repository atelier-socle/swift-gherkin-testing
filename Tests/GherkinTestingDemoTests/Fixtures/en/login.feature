@auth @smoke
Feature: Login
  Users can log in with valid credentials.

  Background:
    Given the app is launched

  Scenario: Successful login
    Given the user is on the login page
    When they enter "alice" and "secret123"
    Then they should see the dashboard

  Scenario: Failed login with wrong password
    Given the user is on the login page
    When they enter "alice" and "wrong"
    Then they should see an error message
