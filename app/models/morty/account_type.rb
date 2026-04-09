module Morty
  class AccountType < ApplicationRecord
    lookup_by :account_type, cache: true

    has_many :accounts
  end
end
