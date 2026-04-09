Feature: Returns

  Create an adjustment activity when an activity is returned.

  Background:
    Given a simulating accountant

      And a start date of 2016-01-01
      And an interest rate of 36.5%
      And the schedule:
       | payment | 2026-01-06 | 1005.00 |

      And I simulate these activities:
        | issue | 2026-01-01 | 1000.00 |

     Then I have these balances:
       | cash      | -1000.00 |
       | principal |  1000.00 |

      And I have 1 issue activity

  Scenario: Return an activity without adjustment
    When I save and reload the accountant
     And I return the 2026-01-01 issue

    Then I have these balances:
      | cash      | 0.00 |
      | principal | 0.00 |

     And these activity counts:
       | issue  | 1 |
       | return | 1 |

  Scenario: Return an activity with adjustment
    When I simulate until 2026-01-02

     And I save and reload the accountant
     And I return the 2026-01-01 issue

    Then I have these balances:
      | cash      | 0.00 |
      | principal | 0.00 |
      | interest  | 0.00 |
      | revenue   | 0.00 |

     And these activity counts:
       | issue      | 1 |
       | return     | 1 |
       | interest   | 1 |
       | adjustment | 1 |

  Scenario: Return an activity entered today
    When I simulate until 2026-01-06

    Then I have these balances:
      | cash      |  5.00 |
      | principal |  0.00 |
      | interest  |  0.00 |
      | revenue   | -5.00 |

     And these activity counts:
       | issue    | 1 |
       | payment  | 1 |
       | interest | 5 |

    When I save and reload the accountant
     And I return the 2026-01-06 payment

    Then I have these balances:
      | cash      | -1000.00 |
      | principal |  1000.00 |
      | interest  |     5.00 |
      | revenue   |    -5.00 |

     And these activity counts:
       | issue    | 1 |
       | payment  | 1 |
       | interest | 5 |
       | return   | 1 |

  Scenario: Return an interleaved activity
    When I simulate these activities:
      | payment | 2026-01-01 | 500.00 |
      | finish  | 2026-01-06 |        |

    Then I have these balances:
      | cash      |  505.00 |
      | principal |    0.00 |
      | interest  |    0.00 |
      | revenue   |   -2.50 |
      | payable   | -502.50 |

     And these activity counts:
       | issue    | 1 |
       | payment  | 2 |
       | interest | 5 |

    When I return the 2026-01-01 payment

    Then I have these balances:
      | cash      |  5.00 |
      | principal |  0.00 |
      | interest  |  0.00 |
      | revenue   | -5.00 |
      | payable   |  0.00 |

     And these activity counts:
       | issue      | 1 |
       | payment    | 2 |
       | interest   | 5 |
       | return     | 1 |
       | adjustment | 1 |
