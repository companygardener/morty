module Morty
  class Ledger < ApplicationRecord
    lookup_by :ledger, cache: true

    has_many :entry_types
    has_many :entries, through: :entry_types
  end
end
