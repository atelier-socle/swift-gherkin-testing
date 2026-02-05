Feature: Data tables

  Scenario: Simple data table
    Given the following users:
      | name  | email           |
      | Alice | alice@test.com  |
      | Bob   | bob@test.com    |
    When I look up users
    Then I should find 2 users

  Scenario: Escaped data table
    Given a table with special characters:
      | value         |
      | pipe \| char  |
      | new\nline     |
      | back\\slash   |
