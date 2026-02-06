@navigation
Feature: Navigation
  Users can navigate between pages.

  Scenario: Navigate to profile
    Given the user is logged in
    When they tap the profile icon
    Then they should see the profile page

  Scenario: Navigate to settings
    Given the user is logged in
    When they tap the settings icon
    Then they should see the settings page
