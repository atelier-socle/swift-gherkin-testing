Feature: Edge cases

  Scenario:
    Given a scenario with no name

  Scenario: Empty steps scenario

  Scenario: Unicode scenario ñ ü ö 日本語
    Given unicode text: café résumé naïve
    Then it works
