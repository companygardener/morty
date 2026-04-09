Feature: Reversal

  Reverse an activity.

  Background:
    Given a simulating accountant

      And a start date of 2026-01-01
      And an interest rate of 0.00%

      And I simulate these activities:
        | issue    | 2026-01-01 | 1000.00 |
        | late_fee | 2026-01-02 |   10.00 |

     Then I have these balances:
       | principal        |  1000.00 |
       | cash             | -1000.00 |
       | late_fee         |    10.00 |
       | late_fee_revenue |   -10.00 |

      And I have a late_fee activity
      And I save and reload the accountant

  Scenario: Reverse an activity
     When I reverse the 2026-01-02 late_fee

     Then I have these balances:
       | principal        |  1000.00 |
       | cash             | -1000.00 |
       | late_fee         |     0.00 |
       | late_fee_revenue |     0.00 |

      And these activity counts:
        | issue    | 1 |
        | late_fee | 1 |
        | reversal | 1 |

  # Cancelling the late fee would make a lot more sense,
  # as it will create the adjustment and zero out the late_fee
  # receivable
  Scenario: Reverse an activity, retroactively
    When I apply a payment for $10
     And I simulate until 2026-01-03

     And I reverse the 2026-01-02 late_fee

    Then I have these balances:
      | principal        | 1000.00 |
      | cash             | -990.00 |
      | late_fee         |  -10.00 |
      | late_fee_revenue |    0.00 |

    And these activity counts:
      | issue    | 1 |
      | late_fee | 1 |
      | payment  | 1 |
      | reversal | 1 |
