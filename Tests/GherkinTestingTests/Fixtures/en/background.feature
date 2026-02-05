Feature: Background example
  Background:
    Given the application is running
    And the database is clean

  Scenario: First scenario
    When action one happens
    Then result one is expected

  Scenario: Second scenario
    When action two happens
    Then result two is expected
