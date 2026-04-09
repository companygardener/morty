puts "Loading spec/dummy/seeds..."

Morty::Engine.load_seed

Morty::Ledger.seed 'aggressive'
Morty::Ledger.lookup.reload

Morty::Seed.accounts %w[
  A cash
  A principal
  A interest
  A receivable
  A principal_late
  A interest_late
  A late_fee

  L payable

  R revenue
  R late_fee_revenue
]

Morty::Seed.entry_types :default, %w[
  cash      principal
  cash      interest
  cash      receivable
  cash      payable
  principal principal_late
  interest  interest_late
  cash      late_fee

  interest  revenue
  late_fee  late_fee_revenue
]

Morty::Seed.entry_types :aggressive, %w[
  cash      principal
  cash      interest
  cash      payable

  interest  revenue
]

Morty::ActivityType.seed *%w[
  default
  interest
  issue
  late_fee
  payment
  refund
  waive_fee
]
