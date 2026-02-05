Feature: Scenario Outline example

  Scenario Outline: Eating cucumbers
    Given there are <start> cucumbers
    When I eat <eat> cucumbers
    Then I should have <left> cucumbers

    @positive
    Examples: Valid amounts
      | start | eat | left |
      |    12 |   5 |    7 |
      |    20 |   5 |   15 |

    @negative
    Examples: Eating too many
      | start | eat | left |
      |    12 |  20 |   -8 |
