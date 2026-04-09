puts "Loading db/seeds... (morty)"

Morty::Ledger.seed 'default'

Morty::Seed.account_types %w[
  A asset     DR
  L liability CR
  E equity    CR
  R revenue   CR
  X expense   DR
]

Morty::ActivityType.seed *%w[
  adjustment
  cancel
  return
  reversal
]
