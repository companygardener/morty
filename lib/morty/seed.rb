module Morty
  module Seed
    # Populate the accounts table
    #
    # Morty::Seed.accounts %w[
    #   cash
    #   interest
    #   principal
    #   principal_late
    #   principal_charged_off
    #   revenue
    # ]
    def self.accounts(list)
      list.each_slice(2) do |type, account|
        Account.where(account: account, account_type_id: type).first_or_create!
      end

      Account.lookup.reload
    end

    # Populate the account_types table
    #
    # Morty::Seed.account_types %w[
    # A Asset     DR
    # X Expense   DR
    # L Liability CR
    # E Equity    CR
    # R Revenue   CR
    # ]
    def self.account_types(list)
      raise ArgumentError, "expected triples" unless list.size % 3 == 0

      list.each_slice(3) do |abbr, type, normal_balance|
        AccountType.find_or_create_by!(account_type_id: abbr) do |at|
          at.account_type   = type
          at.normal_balance = normal_balance.upcase
        end
      end

      AccountType.lookup.reload
    end

    # Populate valid entry_types
    #
    # Morty::Seed.entry_types(:default, %w[
    #   principal      cash
    #   cash           principal
    #   cash           interest
    #   interest       revenue
    #   principal_late principal
    # ]
    def self.entry_types(ledger, list)
      list.each_slice(2) do |dr, cr|
        # Create the entry type and its reverse (debit and credit reversed)
        EntryType.where(ledger: ledger, dr: dr, cr: cr).first_or_create!
        EntryType.where(ledger: ledger, dr: cr, cr: dr).first_or_create!
      end
    end
  end
end
