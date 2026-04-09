Feature: Payment waterfalls

  Background:
    Given a waterfalling accountant
      And a start date of today

  Scenario: No limit
    When I apply an issue activity for $1.00

    Then I have these balances:
      | cash       | -1.00 |
      | receivable |  1.00 |

  Scenario: DR limit
    When I apply these activities:
      | issue   | 1.00 |
      | payment | 1.00 |
      | payment | 2.00 |

    Then I have these balances:
      | cash       |  2.00 |
      | receivable |  0.00 |
      | payable    | -2.00 |

  Scenario: CR limit
    When I apply these activities:
      | payment | 1.00 |
      | refund  | 1.00 |
      | refund  | 2.00 |

    Then I have these balances:
      | cash       | -2.00 |
      | receivable |  2.00 |
      | payable    |  0.00 |
