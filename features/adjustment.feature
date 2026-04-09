Feature: Adjustment

  An adjustment activity is created when recording an activity with an effective_date in the past

  Background:
    Given an adjusting accountant
      And a start date of 2016-01-01
      And an interest rate of 36.5%

      And I simulate these activities:
       | issue | 2026-01-01 | 1000.00 |

     Then I have 1 issue activity

  Scenario: One retroactive payment
    When I simulate until 2026-01-03
     And I apply a payment effective 2026-01-02 for $500.00

    Then I have these balances:
      | cash      | -500.00 |
      | principal |  501.00 |
      | interest  |    0.50 |
      | revenue   |   -1.50 |

     And I have these activity counts:
       | issue      | 1 |
       | payment    | 1 |
       | adjustment | 1 |
       | interest   | 2 |

  Scenario: Two retroactive payments
    When I simulate until 2026-01-04
     And I apply a payment effective 2026-01-03 for $500.00

    Then I have these balances:
      | cash      | -500.00 |
      | principal |  502.00 |
      | interest  |    0.50 |
      | revenue   |   -2.50 |

    When I simulate until 2026-01-05
     And I apply a payment effective 2026-01-02 for $400.00

    Then I have these balances:
      | cash      | -100.00 |
      | principal |  101.60 |
      | interest  |    0.20 |
      | revenue   |   -1.80 |

     And I have these activity counts:
       | issue      | 1 |
       | payment    | 2 |
       | adjustment | 2 |
       | interest   | 4 |

  Scenario: Two retroactive payments interleaved
    When I simulate until 2026-01-04
     And I apply a payment effective 2026-01-02 for $400.00

    Then I have these balances:
      | cash      | -600.00 |
      | principal |  601.00 |
      | interest  |    1.20 |
      | revenue   |   -2.20 |

    When I simulate until 2026-01-05
     And I apply a payment effective 2026-01-03 for $500.00

    Then I have these balances:
      | cash      | -100.00 |
      | principal |  101.60 |
      | interest  |    0.20 |
      | revenue   |   -1.80 |

     And these activity counts:
       | issue      | 1 |
       | payment    | 2 |
       | adjustment | 2 |
       | interest   | 4 |
