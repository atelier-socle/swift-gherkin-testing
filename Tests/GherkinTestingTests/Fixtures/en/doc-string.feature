Feature: Doc strings

  Scenario: Triple quote doc string
    Given the following text:
      """
      Hello, World!
      This is a multiline
      doc string.
      """
    Then the text should be parsed

  Scenario: Backtick doc string with media type
    Given the following JSON:
      ```json
      {
        "name": "test",
        "value": 42
      }
      ```
    Then the JSON should be valid
