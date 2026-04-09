module Morty
  class Book
    attr_reader :accountant, :ledger

    def initialize(ledger, accountant:)
      raise "missing ledger" unless ledger

      @ledger     = ledger
      @accountant = accountant
    end

    def accounts
      accountant.accounts(ledger)
    end

    def apply(entry)
      case entry
      when Entry
        accounts[entry.dr] += entry.amount
        accounts[entry.cr] -= entry.amount
      when Activity
        entry.entries.select { |e| e.ledger == ledger }.each do |entry|
          apply(entry)
        end
      end
    end

    def balances_list
      accountant.balances_list[ledger]
    end

    # can define per ledger
    #
    # returns { balance_name => value }
    def balances
      balances_list.to_h { |label, list| [label, list.sum { |name| accounts[name] }] }
    end

    def entry(dr, cr, amount, activity:)
      amount = amount.try(:to_d)

      return if amount.nil? || amount.zero?

      raise "entry amount cannot be negative" if amount < 0

      type = EntryType.find_by_accounts(dr, cr, ledger)

      entry = activity.entries.build(entry_type: type, amount: amount)

      apply(entry)
      entry
    end
  end
end
