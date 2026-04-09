module Morty
  class EntryType < ApplicationRecord
    lookup_for :dr,     class_name: Account, symbolize: true
    lookup_for :cr,     class_name: Account, symbolize: true
    lookup_for :ledger, class_name: Ledger,  symbolize: true

    has_many :entries

    def self.find_by_accounts(dr, cr, ledger = :default)
      all.detect { |obj| obj.dr == dr &&
                         obj.cr == cr &&
                         obj.ledger == ledger }
    end

    def inverse
      self.class.find_by_accounts(cr, dr, ledger)
    end

    def inspect
      "#<EntryType[%2s] %s ledger DR[%-20s] CR[%-20s]>" % [id, ledger, dr, cr]
    end
  end
end
