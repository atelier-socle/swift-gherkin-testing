# This is a full specification feature file
@full @spec
Feature: Full specification
  This feature exercises every element of the Gherkin syntax.
  It includes all keywords and constructs.

  Background:
    Given the system is initialized
    And logging is enabled

  # A simple scenario
  @smoke
  Scenario: Basic operations
    Given a clean state
    When an operation is performed
    And another operation follows
    But a constraint is checked
    Then the result is correct
    * the logs are updated

  Scenario Outline: Parameterized test
    Given a value of <input>
    When processed
    Then the output is <output>

    Examples: Normal cases
      | input | output |
      | foo   | FOO    |
      | bar   | BAR    |

    Examples: Edge cases
      | input | output |
      |       |        |

  Rule: Special handling
    Background:
      Given special mode is enabled

    @critical
    Scenario: Special scenario
      Given a special condition
      When the special action occurs
      Then the special result is produced

    Scenario: Doc string usage
      Given a payload:
        """json
        {"key": "value"}
        """
      Then it is processed

    Scenario: Data table usage
      Given these items:
        | id | name  |
        | 1  | alpha |
        | 2  | beta  |
      Then all items are stored
