@feature-tag
Feature: Tags example

  @smoke @fast
  Scenario: Tagged scenario
    Given something
    Then something else

  @wip
  Scenario Outline: Tagged outline
    Given <value>
    Then result

    @dataset-1
    Examples:
      | value |
      | alpha |

    @dataset-2
    Examples:
      | value |
      | beta  |
