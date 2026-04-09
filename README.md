# Morty

Morty is an accountant.

**Depends on:**

* Rails 7.0+ (tested on 7.0, 7.1, 7.2, 8.0, 8.1)
* Ruby 3.2+ (tested on 3.2, 3.3, 3.4, 4.0)
* LookupBy ([edge][lookup_by], for now)
* PostgreSQL 9.5+ (tested on 16)

Source code

* [github.com/companygardener/morty][source]

## Installation

Add this line to your application's Gemfile:

    gem 'morty'

And then execute:

    $ bundle install

Run migrations (Morty is an engine and includes its own migrations):

    $ rake db:migrate

## Usage

Morty uses double-entry bookkeeping. You define an `Accountant` subclass that
declares activities (transactions) and how they move money between accounts.

### Define an Accountant

```ruby
class LoanAccountant < Morty::Accountant
  # The source ties all activities to a domain object (e.g. a Loan).
  source :loan

  # Named balances aggregate one or more accounts.
  balance :accruing, %w[principal]

  # Activities describe double-entry transactions.
  # Each entry debits one account and credits another.
  activity :issue do
    entry :principal, :cash, amount
  end

  activity :interest do
    entry :interest, :revenue, amount
  end

  # Waterfalls apply a payment across accounts in priority order.
  # `limit: :cr` caps each entry at the credit account's balance.
  # `complete: true` sends any remainder to the last account.
  waterfall :payment, limit: :cr, complete: true, entries: <<~END
    cash interest
    cash principal
    cash payable
  END

  # Daily logic runs once per simulated day.
  daily do
    activity :interest, today, rate.daily * balances[:accruing]
  end

  # Guard prevents duplicate daily entries.
  daily_guard do
    accountant.activities.with_type(:interest).none? { |a| a.effective_date == accountant.date }
  end
end
```

### Seed the Schema

Morty needs account types, accounts, entry types, and activity types seeded
before use. The engine includes a base seed file; add your domain-specific
seeds on top:

```ruby
# Load Morty's base seeds (account types, built-in activity types)
Morty::Engine.load_seed

# Your ledger
Morty::Ledger.seed 'default'

# Accounts: pairs of [account_type_abbreviation, account_name]
Morty::Seed.accounts %w[
  A cash
  A principal
  A interest
  L payable
  R revenue
]

# Entry types: pairs of [debit_account, credit_account]
# Morty creates the reverse entry type automatically.
Morty::Seed.entry_types :default, %w[
  cash      principal
  cash      interest
  cash      payable
  interest  revenue
]

# Activity types your accountant uses
Morty::ActivityType.seed *%w[issue interest payment]
```

### Record Activities

```ruby
accountant = LoanAccountant.new
accountant.source     = loan       # any object with an #id method
accountant.start_date = loan.funded_on

# Record a single activity
accountant.activity :issue, "2026-01-01", 5000

# Set a schedule of future activities
accountant.schedule = [
  { type: :payment, date: "2026-02-01", amount: 500 },
  { type: :payment, date: "2026-03-01", amount: 500 },
]

# Simulate forward in time (runs daily logic + scheduled activities for each day)
accountant.simulate_to("2026-03-01")

# Check balances
accountant.balances  # => { accruing: 4123.45 }
accountant.accounts  # => { cash: -4000, principal: 4123.45, interest: 0, ... }

# Save all activities and entries to the database
accountant.save
```

### Cancellations and Reversals

```ruby
# Cancel an activity (creates a cancelling counter-entry)
incorrect = accountant.activities.last
accountant.cancel(incorrect)

# Reverse an activity (creates reversal entries)
accountant.reverse(prior_activity)
```

### Debugging

Every activity has a `debug` method that prints a colorized ledger view:

```ruby
activity = accountant.activities.last
activity.debug

# Issue $5000.00 2026-01-01
#
# Default ledger entries
#
#              |        DR |       CR
# ------------|-----------|----------
#   principal |   5000.00 |
#        cash |           |   5000.00
```

You can also inspect the activity list:

```ruby
accountant.activities.each { |a| puts a.inspect }
# #<Activity[new]  $ 5000.00 2026-01-01            issue>
# #<Activity[new]  $    1.00 2026-01-02            interest>

# Filter by type
accountant.activities.with_type(:interest).count
accountant.activities.count_by_type  # => { issue: 1, interest: 31, payment: 2 }

# Inspect an activity's entries
activity.entries.each { |e| puts e.inspect }
# #<Entry[new] $5000.00 default DR[principal] CR[cash]>

# Each entry exposes its debit/credit accounts and ledger
entry = activity.entries.first
entry.dr      # => :principal
entry.cr      # => :cash
entry.amount  # => 5000.0
entry.ledger  # => :default
```

## Testing

Morty uses rspec and cucumber. Install them:

    $ bundle install

Run the test suite:

    $ rake db:reset
    $ rake

## Cucumber Steps

Morty ships reusable Cucumber steps. Require them in your `features/support/env.rb`:

```ruby
require "morty/cucumber/steps"
```

Then write features using the built-in step vocabulary:

```gherkin
Feature: Loan lifecycle

  Scenario: Issue and pay down a loan
    Given a loan accountant
      And a start date of 2026-01-01
      And an interest rate of 36.5%
      And the schedule:
        | payment | 2026-02-01 | 500.00 |
        | payment | 2026-03-01 | 500.00 |

    When I simulate until 2026-03-01

    Then I have these balances:
      | cash      | -4000.00 |
      | principal |  4123.45 |
      | interest  |     0.00 |
      | revenue   |  -123.45 |
```

### Available Steps

**Setup:**

| Step | Example |
|---|---|
| `Given a <type> accountant` | `Given a loan accountant` |
| `Given a start date of <date>` | `Given a start date of 2026-01-01` |
| `Given an interest rate of <rate>%` | `Given an interest rate of 36.5%` |
| `Given the schedule:` | Table of `\| type \| date \| amount \|` rows |
| `Given the interest rates:` | Table of `\| date \| rate \|` rows |

**Actions:**

| Step | Example |
|---|---|
| `When I simulate to/until <date>` | `When I simulate until 2026-03-01` |
| `When I simulate these activities:` | Table of `\| type \| date \| amount \|` rows |
| `When I apply a <type> for $<amount>` | `When I apply a payment for $500.00` |
| `When I apply a <type> effective <date> for $<amount>` | Retroactive activity |
| `When I cancel the <date> <type>` | `When I cancel the 2026-01-15 payment` |
| `When I return the <date> <type>` | `When I return the 2026-01-15 payment` |
| `When I reverse the <date> <type>` | `When I reverse the 2026-01-15 interest` |
| `When I save and reload the accountant` | Persists and reloads from the database |

**Assertions:**

| Step | Example |
|---|---|
| `Then I have these balances:` | Table of `\| account \| amount \|` rows |
| `Then all zero balances` | All accounts are zero |
| `Then I have <n> activities` | `Then I have 5 activities` |
| `Then I have these activity counts:` | Table of `\| type \| count \|` rows |
| `Then the <name> ledger has these balances:` | For multi-ledger accountants |

The accountant step (`Given a loan accountant`) expects a class named
`LoanAccountant` to exist. Define your accountant classes in
`features/support/` so they're loaded before your features run.

## Contributing

1. Fork it ( https://github.com/[my-github-username]/morty/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Copyright

Copyright © 2025-2026 Erik Peterson. Licensed under the MIT License.

[source]:    https://github.com/companygardener/morty     "Morty source"
[lookup_by]: https://github.com/companygardener/lookup_by "LookupBy source"
