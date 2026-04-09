Feature: Retroactive Activities

  Create activities that are accounted for in present, but effective in the past.

  Background:
    Given a simulating accountant
      And a start date of 2026-01-01
      And an interest rate of 36.5%

  Scenario: Retroactive activity

     When I simulate to 2026-01-03

     Then I have all zero balances

     When I apply an issue activity effective 2026-01-01 for $1000.00

     Then I have these balances:
       | cash      | -1000.00 |
       | principal |  1000.00 |
       | interest  |     2.00 |
       | revenue   |    -2.00 |

     And I have these activity counts:
       | issue      | 1 |
       | adjustment | 1 |

  Scenario: Retroactive activity with adjustment

     When I simulate these activities:
       | issue  | 2026-01-01 | 1000.00 |
       | finish | 2026-01-02 |         |

     Then I have these balances:
       | cash      | -1000.00 |
       | principal |  1000.00 |
       | interest  |     1.00 |
       | revenue   |    -1.00 |

     When I apply a payment activity effective 2026-01-01 for $1000.00

     Then I have all zero balances
      And I have these activity counts:
       | issue      | 1 |
       | payment    | 1 |
       | interest   | 1 |
       | adjustment | 1 |

  Scenario: Cancelling a retroactive activity

     When I simulate these activities:
       | issue  | 2026-01-01 | 1000.00 |
       | finish | 2026-01-02 |         |

      And I apply a payment activity effective 2026-01-01 for $500.00

     Then I have these balances:
       | cash      | -500.00 |
       | principal |  500.00 |
       | interest  |    0.50 |
       | revenue   |   -0.50 |

     When I simulate to 2026-01-03

     Then I have these balances:
       | cash      | -500.00 |
       | principal |  500.00 |
       | interest  |    1.00 |
       | revenue   |   -1.00 |

     When I cancel the 2026-01-01 payment

     Then I have these balances:
       | cash      | -1000.00 |
       | principal |  1000.00 |
       | interest  |     2.00 |
       | revenue   |    -2.00 |

     When I save and reload the accountant

     Then I have these balances:
       | cash      | -1000.00 |
       | principal |  1000.00 |
       | interest  |     2.00 |
       | revenue   |    -2.00 |

      And I have these activity counts:
       | issue      | 1 |
       | interest   | 2 |
       | payment    | 1 |
       | cancel     | 1 |
       | adjustment | 2 |
