Feature: Simulation

  Background:
    Given a simulating accountant
      And a start date of 2026-01-01
      And an interest rate of 36.5%
      And the schedule:
        | payment | 2026-01-11 | 1010.00 |

  Scenario: No start date
    Given the accountant:
      """
        @accountant = SimulatingAccountant.new
      """
     Then the accountant is valid
      But I cannot simulate

  Scenario: Same day payoff
    When I simulate these activities:
      | issue   | 2026-01-01 | 100.00 |
      | payment | 2026-01-01 | 100.00 |

    Then I have these balances:
      | cash      | 0.00 |
      | principal | 0.00 |

  Scenario: Next-Day Payment
    When I simulate these activities:
      | issue   | 2026-01-01 | 1000.00 |
      | payment | 2026-01-02 | 1000.00 |

    Then I have these balances:
      | cash      |  0.00 |
      | principal |  1.00 |
      | interest  |  0.00 |
      | revenue   | -1.00 |

     And I have these activity counts:
       | issue    | 1 |
       | payment  | 1 |
       | interest | 1 |

  Scenario: Simulation with scheduled activity
    When I simulate these activities:
      | issue  | 2026-01-01 | 1000.00 |
      | finish | 2026-01-11 |         |

    Then I have these balances:
      | cash      |  10.00 |
      | principal |   0.00 |
      | interest  |   0.00 |
      | revenue   | -10.00 |

    And I have these activity counts:
      | issue    |  1 |
      | payment  |  1 |
      | interest | 10 |

    And I save the accountant

   When I reload the accountant with a start date of 2026-01-02
   Then I have these balances:
     | cash      | -1000.00 |
     | principal |  1000.00 |
     | interest  |     1.00 |
     | revenue   |    -1.00 |

   And I have these activity counts:
     | issue    | 1 |
     | interest | 1 |

  When I reload the accountant with a start_date of 2026-01-11
  Then I have these balances:
    | cash      |  10.00 |
    | principal |   0.00 |
    | interest  |   0.00 |
    | revenue   | -10.00 |

   And I have these activity counts:
     | issue    |  1 |
     | payment  |  1 |
     | interest | 10 |

  Scenario: Multiple interest rates
    Given a simulating accountant
      And a start date of 2026-01-01
      And the interest rates:
        | effective_date | rate |
        | 2026-01-01     | 36.5 |
        | 2026-01-02     |    0 |
        | 2026-01-03     | 36.5 |

    When I simulate these activities:
      | issue  | 2026-01-01 | 1000.0 |
      | finish | 2026-01-04 |        |

    Then I have these balances:
      | cash      | -1000.00 |
      | principal |  1000.00 |
      | interest  |     2.00 |
      | revenue   |    -2.00 |

  Scenario: Daily interest rate, payment on start date
    Given a simulating accountant
      And a start date of 2026-01-01
      And a daily interest rate of 1.00%
      And the schedule:
        | issue   | 2026-01-01 | 1000.00|
        | payment | 2026-01-01 | 500.00 |

     When I simulate until 2026-01-01
     Then I have these balances:
       | cash      | -500.00 |
       | principal |  500.00 |

     When I simulate until 2026-01-01
     Then I have these balances:
       | cash      | -500.00 |
       | principal |  500.00 |

     When I save the accountant
      And I reload the accountant with a start date of 2026-01-03
      And I simulate until 2026-01-03
     Then I have these balances:
       | cash      | -500.00 |
       | principal |  500.00 |
       | interest  |    5.00 |
       | revenue   |   -5.00 |
