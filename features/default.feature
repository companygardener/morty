Feature: Default

  Scenario: Late principal and interest
    Given a defaulting accountant
      And a start date of 2026-01-01
      And an interest rate of 36.5%

      And the schedule:
        | issue   | 2026-01-01 | 1000.00 |
        | default | 2026-02-01 |  100.00 |
        | default | 2026-03-01 |  100.00 |

    When I simulate until 2026-02-01

    Then I save and reload the accountant
     And I have these balances:
       | cash           | -1000.00 |
       | principal      |   931.00 |
       | principal_late |    69.00 |
       | interest       |     0.00 |
       | interest_late  |    31.00 |
       | revenue        |   -31.00 |

     When I simulate until 2026-03-01

     Then I save and reload the accountant
      And I have these balances:
        | cash           | -1000.00 |
        | principal      |   859.00 |
        | principal_late |   141.00 |
        | interest       |     0.00 |
        | interest_late  |    59.00 |
        | revenue        |   -59.00 |
