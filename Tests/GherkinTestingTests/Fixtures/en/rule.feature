@billing
Feature: Billing rules

  Background:
    Given I am logged in

  Rule: Free accounts
    Background:
      Given I have a free account

    Scenario: Cannot access premium features
      When I try to access premium features
      Then I should see an upgrade prompt

  Rule: Premium accounts
    Background:
      Given I have a premium account

    Scenario: Can access all features
      When I access premium features
      Then I should see the content
