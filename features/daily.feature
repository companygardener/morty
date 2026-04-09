Feature: Daily

  An accountant can define a daily process to run during a simulation.
  It may accrue daily interest, assess late fees, default principal balances, etc.

  In addition, it could be the actual process used to perform these activities on a daily basis.

  Background:
    Given a daily accountant
      And a start date of today
      And an interest rate of 36.5%

  Scenario: Daily guard passes
    When I run the daily for today
    Then I have an interest activity

  Scenario: Daily guard fails
    When I run the daily for today
    Then I have 1 activity

    When I run the daily for tomorrow
    Then I still have 1 activity

    When I run the daily for 2 days from now
    Then I have 2 activities

     And I have these balances:
       | interest |  2.00 |
       | revenue  | -2.00 |

  Scenario: Daily runs only once
    Given a simulating accountant
      And a start date of today
      And an interest rate of 36.5%
      And I simulate these activities:
        | issue | 1000.00 |

     When I run the daily for tomorrow
     Then I have 1 interest activity

     When I run the daily for tomorrow
     Then I have 1 interest activity
