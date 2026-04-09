Feature: Ledgers

  Background:
    Given a multiple ledgers accountant
      And a start date of 2026-01-01
      And an interest rate of 36.5%
      And the schedule:
        | payment | 2026-01-06 | 1005.00 |

  Scenario: Different dailies
    When I simulate these activities:
      | issue  | 2026-01-01 | 1000.00 |
      | finish | 2026-01-06 |         |

    Then the default ledger has these balances:
      | cash      |  5.00 |
      | principal |  0.00 |
      | interest  |  0.00 |
      | revenue   | -5.00 |

     And the aggressive ledger has these balances:
      | cash      |   5.00 |
      | principal |  45.00 |
      | interest  |   0.00 |
      | revenue   | -50.00 |

     And I have these activity counts:
      | issue    | 1 |
      | payment  | 1 |
      | interest | 5 |

    When I save and reload the accountant

    Then I have these activity counts:
      | issue    | 1 |
      | payment  | 1 |
      | interest | 5 |

     And the default ledger has these balances:
      | cash      |  5.00 |
      | principal |  0.00 |
      | interest  |  0.00 |
      | revenue   | -5.00 |

     And the default ledger has these aggregated balances:
      | accruing | 0.00 |
      | varying  | 0.00 |

     And the aggressive ledger has these balances:
      | cash      |   5.00 |
      | principal |  45.00 |
      | interest  |   0.00 |
      | revenue   | -50.00 |

     And the aggressive ledger has these aggregated balances:
      | accruing | 45.00 |
      | varying  | 50.00 |
