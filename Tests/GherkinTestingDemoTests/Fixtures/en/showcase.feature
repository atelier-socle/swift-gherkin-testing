# language: en
# ============================================================================
# Showcase Feature — E-Commerce Application
# Demonstrates every Gherkin construct supported by swift-gherkin-testing
# ============================================================================

@showcase @regression
Feature: E-Commerce Shopping Experience
  As a customer of an online store
  I want to browse products, manage my cart, and checkout
  So that I can purchase items conveniently

  # Background runs before every scenario in this feature
  Background:
    Given the store is open
    And the product catalog is loaded

  # --- Basic Scenario: simple Given/When/Then ---

  @smoke
  Scenario: Browse product catalog
    When the customer views the catalog
    Then they should see at least 1 products

  # --- Scenario with And / But ---

  @smoke
  Scenario: Add item to cart with quantity check
    Given the customer is logged in as "alice"
    When they add "Wireless Mouse" to the cart
    And they add "USB Keyboard" to the cart
    Then the cart should contain 2 items
    But the cart total should not be 0.00

  # --- Cucumber Expressions: {string}, {int}, {float} ---

  @pricing
  Scenario: Apply discount to cart
    Given the customer is logged in as "bob"
    And the cart contains "Laptop Stand" at 49.99
    When they apply the discount code "SAVE20"
    Then the cart total should be 39.99

  # --- DataTable scenario ---

  @catalog
  Scenario: Verify product catalog entries
    When the customer views the catalog
    Then the following products should be available:
      | name           | price  | status |
      | Wireless Mouse | 29.99  | active |
      | USB Keyboard   | 59.99  | active |
      | Laptop Stand   | 49.99  | active |
      | HDMI Cable     | 14.99  | active |

  # --- DocString scenario ---

  @api
  Scenario: Submit product review
    Given the customer is logged in as "alice"
    When they submit a review for "Wireless Mouse" with:
      """json
      {
        "rating": 5,
        "title": "Excellent mouse!",
        "body": "Very comfortable and responsive. Battery lasts forever."
      }
      """
    Then the review should be submitted successfully

  # --- Mixed: captured args + DataTable ---

  @cart
  Scenario: Bulk add items to cart
    Given the customer is logged in as "alice"
    When they add 3 items to the cart:
      | product        | quantity |
      | Wireless Mouse | 2        |
      | USB Keyboard   | 1        |
      | HDMI Cable     | 3        |
    Then the cart should contain 6 items

  # --- Custom parameter types: {status} and {currency} ---

  @admin @edge-case
  Scenario: Filter products by status
    Given the customer is logged in as "alice"
    When they filter products by status active
    Then they should see at least 4 products

  @pricing
  Scenario: Display price in currency
    Given the customer is logged in as "bob"
    And the cart contains "Laptop Stand" at 49.99
    When they select currency EUR
    Then the displayed currency should be EUR

  # ============================================================================
  # Rule: Gherkin 6+ grouping construct
  # ============================================================================

  Rule: Checkout requires authentication

    # Scenarios inside a Rule inherit the Feature's Background

    @checkout @smoke
    Scenario: Guest cannot checkout
      When a guest tries to checkout
      Then they should be redirected to login

    @checkout
    Scenario: Authenticated user can checkout
      Given the customer is logged in as "alice"
      And the cart contains "Wireless Mouse" at 29.99
      When they proceed to checkout
      Then the order should be confirmed

    @checkout @edge-case
    Scenario: Empty cart cannot checkout
      Given the customer is logged in as "bob"
      When they proceed to checkout
      Then they should see the error "Cart is empty"

  # ============================================================================
  # Scenario Outline: parameterized scenarios with Examples
  # ============================================================================

  @outline
  Scenario Outline: Login with various credentials
    Given the customer navigates to login
    When they attempt login with "<username>" and "<password>"
    Then the login result should be "<result>"

    @positive
    Examples: Valid credentials
      | username | password   | result    |
      | alice    | secret123  | success   |
      | bob      | password456| success   |

    @negative
    Examples: Invalid credentials
      | username | password | result               |
      | alice    | wrong    | invalid_credentials  |
      | nobody   | test     | invalid_credentials  |
      | alice    |          | invalid_credentials  |
      |          | secret123| invalid_credentials  |

  # --- Large Scenario Outline: ~100 examples for performance testing ---

  @outline @performance
  Scenario Outline: Add product with price validation
    Given the customer is logged in as "alice"
    When they add "<product>" at <price> to the cart
    Then the item "<product>" should be in the cart at <price>

    @positive
    Examples: Standard products
      | product              | price  |
      | Wireless Mouse       | 29.99  |
      | USB Keyboard         | 59.99  |
      | Laptop Stand         | 49.99  |
      | HDMI Cable           | 14.99  |
      | Webcam HD            | 79.99  |
      | Monitor Arm          | 39.99  |
      | Desk Lamp            | 24.99  |
      | Mouse Pad XL         | 19.99  |
      | USB Hub 4-Port       | 12.99  |
      | Cable Management Kit | 9.99   |
      | Screen Protector     | 7.99   |
      | Laptop Sleeve 15in   | 34.99  |
      | Phone Holder         | 15.99  |
      | Bluetooth Speaker    | 44.99  |
      | Power Strip 6-Outlet | 22.99  |
      | Ergonomic Wrist Rest | 17.99  |
      | Desk Organizer       | 27.99  |
      | LED Strip Lights     | 18.99  |
      | Wireless Charger     | 25.99  |
      | Headphone Stand      | 21.99  |
      | Mini Projector       | 89.99  |
      | Portable SSD 1TB     | 99.99  |
      | Mechanical Keyboard  | 129.99 |
      | Noise Cancel Headset | 149.99 |
      | Drawing Tablet       | 69.99  |
      | USB Microphone       | 54.99  |
      | Ring Light 10in      | 32.99  |
      | Tripod Stand         | 28.99  |
      | Camera Lens Kit      | 42.99  |
      | Action Camera        | 119.99 |
      | Drone Mini           | 199.99 |
      | Smart Watch Band     | 11.99  |
      | Fitness Tracker      | 39.99  |
      | VR Headset           | 249.99 |
      | Game Controller      | 45.99  |
      | Racing Wheel         | 179.99 |
      | Flight Stick         | 89.99  |
      | Capture Card         | 129.99 |
      | Stream Deck          | 149.99 |
      | Green Screen         | 34.99  |
      | Studio Lights Kit    | 64.99  |
      | Boom Arm             | 29.99  |
      | Pop Filter           | 8.99   |
      | Audio Interface      | 109.99 |
      | MIDI Keyboard        | 79.99  |
      | Studio Monitors      | 199.99 |
      | Acoustic Panels 4pk  | 44.99  |
      | Cable Tester         | 19.99  |
      | Network Switch 8P    | 24.99  |
      | Ethernet Cable 50ft  | 12.99  |

    @negative
    Examples: Edge case prices
      | product              | price    |
      | Free Sample          | 0.00    |
      | Penny Item           | 0.01    |
      | Budget Widget        | 0.99    |
      | Dollar Store Item    | 1.00    |
      | Clearance Bin        | 1.49    |
      | Bargain Box          | 2.99    |
      | Economy Pack         | 3.50    |
      | Value Bundle         | 4.99    |
      | Basic Kit            | 5.00    |
      | Starter Set          | 5.99    |
      | Intro Pack           | 6.49    |
      | Trial Size           | 7.00    |
      | Mini Version         | 7.50    |
      | Compact Model        | 8.00    |
      | Lite Edition         | 8.50    |
      | Express Ship Add-on  | 9.00    |
      | Gift Wrap Option     | 2.50    |
      | Extended Warranty 1Y | 14.99   |
      | Extended Warranty 2Y | 24.99   |
      | Extended Warranty 3Y | 34.99   |
      | Premium Support      | 49.99   |
      | Setup Service        | 29.99   |
      | Data Transfer Svc    | 19.99   |
      | Recycling Fee        | 3.99    |
      | Restocking Fee       | 7.99    |
      | Rush Processing      | 12.99   |
      | Insurance Basic      | 4.99    |
      | Insurance Premium    | 9.99    |
      | Personalization      | 6.99    |
      | Monogramming         | 11.99   |
      | Custom Engraving     | 15.99   |
      | Color Upgrade        | 5.99    |
      | Size Upgrade S to M  | 3.99    |
      | Size Upgrade M to L  | 3.99    |
      | Size Upgrade L to XL | 4.99    |
      | Material Upgrade     | 8.99    |
      | Eco Packaging        | 1.99    |
      | Premium Packaging    | 4.99    |
      | Holiday Packaging    | 2.99    |
      | Sample Pack 3-Item   | 9.99    |
      | Sample Pack 5-Item   | 14.99   |
      | Mystery Box Small    | 19.99   |
      | Mystery Box Medium   | 34.99   |
      | Mystery Box Large    | 49.99   |
      | Gift Card 10         | 10.00   |
      | Gift Card 25         | 25.00   |
      | Gift Card 50         | 50.00   |
      | Gift Card 100        | 100.00  |
      | Subscription Monthly | 9.99    |
      | Subscription Annual  | 99.99   |
