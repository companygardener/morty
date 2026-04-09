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

The migration creates two PostgreSQL schemas:

- **`morty`** ... ledgers, account_types, accounts, activity_types, activities, entries, and a set of accounting views (balances, details, drs/crs)
- **`morty_archive`** ... mirrors the activities and entries tables for closed-period data, with foreign key constraints removed for fast bulk inserts

Both schemas enforce write-only access at the database level. Triggers prevent updates and deletes on activities, entries, and entry_types unless explicitly overridden.

## Features

- **Double-entry bookkeeping** ... every activity creates balanced debit/credit entries
- **Write-only ledger** ... activities and entries cannot be updated or deleted at the database level; corrections are made through cancellations and reversals
- **Multiple ledgers** ... run different accounting strategies side by side (e.g. conservative vs aggressive interest accrual) against the same source
- **Retroactive activities** ... backdate an activity with `effective_date:` and Morty automatically recalculates all affected entries from that date forward
- **In-memory simulation** ... simulate days forward, running daily logic and scheduled activities, before deciding whether to persist
- **Effective rates** ... attach rate schedules that change over time; `rate_for(date)` resolves the correct rate for any point in history
- **Period archival** ... move closed-period data to `morty_archive` to keep the active schema lean

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

# Set interest rates (annual, keyed by effective date)
accountant.rates = {
  "2026-01-01" => 0.365,   # 36.5% APR
  "2026-07-01" => 0.24,    # drops to 24% APR on July 1
}

# Record a single activity
accountant.activity :issue, "2026-01-01", 5000

# Pass an idempotent_uuid to safely retry from webhooks or queues
accountant.activity :payment, "2026-02-01", 500, idempotent_uuid: "550e8400-..."

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

### Simulation

`simulate_to` is a shortcut for the more flexible `simulate` block. Inside
a simulation block, you can interleave activities with time advancement
using `finish`:

```ruby
accountant.simulate do
  issue   "2026-01-01", 1000
  payment "2026-01-02", 1000
end

# finish advances the simulation day-by-day (running daily logic each day)
# without recording an activity:
accountant.simulate do
  issue  "2026-01-01", 1000
  finish "2026-01-11"          # run daily interest through Jan 11
end
```

The simulation runs entirely in memory. Nothing is persisted until you
call `accountant.save`. This makes it cheap to explore scenarios:

```ruby
# What would balances look like if we waited until March?
trial = accountant.adjusting_accountant
trial.simulate_to("2026-03-01")
trial.balances  # => { accruing: 4500.00 }
# nothing saved, original accountant unchanged
```

### Cancellations and Reversals

```ruby
# Cancel an activity (creates a cancelling counter-entry)
incorrect = accountant.activities.last
accountant.cancel(incorrect)

# Reverse an activity (creates reversal entries)
accountant.reverse(prior_activity)
```

### Retroactive Activities

Record an activity today that takes effect in the past. Morty replays history
from the effective date forward and generates an adjustment entry to correct
all downstream balances (e.g. accrued interest).

```ruby
# Issue was funded on Jan 1, but we're recording it on Jan 3
accountant.simulate_to("2026-01-03")
accountant.activity :issue, "2026-01-03", 1000, effective_date: "2026-01-01"

# Morty automatically:
# 1. Replays simulation from the effective date
# 2. Recalculates daily interest from Jan 1 through Jan 3
# 3. Creates an :adjustment activity with correcting entries
accountant.activities.count_by_type
# => { issue: 1, interest: 2, adjustment: 1 }
```

Cancelling a retroactive activity also triggers readjustment:

```ruby
# Cancel the payment that was effective Jan 1
accountant.cancel(payment_activity)
# Interest is recalculated as if the payment never happened
```

### Debugging

Every activity has a `debug` method that prints a colorized ledger view:

```
activity = accountant.activities.last
activity.debug

# Issue $5000.00 2026-01-01
#
# Default ledger entries
#
#             |        DR |       CR
# ------------|-----------|----------
#   principal |   5000.00 |
#        cash |           |   5000.00
```

You can also inspect the activity list:

```ruby
accountant.activities.each { |a| puts a.inspect }
# <Activity[new]  $ 5000.00 2026-01-01            issue>
# <Activity[new]  $    1.00 2026-01-02            interest>

# Filter by type
accountant.activities.with_type(:interest).count
accountant.activities.count_by_type  # => { issue: 1, interest: 31, payment: 2 }

# Inspect an activity's entries
activity.entries.each { |e| puts e.inspect }
# <Entry[new] $5000.00 default DR[principal] CR[cash]>

# Each entry exposes its debit/credit accounts and ledger
entry = activity.entries.first
entry.dr      # => :principal
entry.cr      # => :cash
entry.amount  # => 5000.0
entry.ledger  # => :default
```

### Period Closing and Archival

Morty provides three PostgreSQL functions for managing historical data.
Call them directly via SQL.

**Close a period** ... marks a ledger as closed through a given date. The
ledger must balance (debits equal credits) through that date or the call
raises an exception.

```sql
SELECT morty.close_period(1, '2025-12-31');
```

**Archive by source** ... moves all activities and entries for a source
into `morty_archive`. The source must have no entries in any open period.

```sql
SELECT * FROM morty.archive_source(1234);
-- => archived_activities | archived_entries
--    47                  | 312
```

**Archive by date** ... moves all activities and entries on or before a
date into `morty_archive`. All ledgers must be closed through that date
first.

```sql
SELECT * FROM morty.archive_through('2025-12-31');
-- => archived_activities | archived_entries
--    10842               | 89431
```

Archived data is queryable through the same view structure in the
`morty_archive` schema. The archive tables mirror the active schema but
without foreign key constraints, so bulk inserts are fast.

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
