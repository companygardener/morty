module Morty
  class Entry < ApplicationRecord
    belongs_to :activity
    belongs_to :entry_type

    delegate :ledger, :dr, :cr, to: :type

    def inspect
      if type
        "#<Entry[%s] $%.2f %s DR[%s] CR[%s]>" % [id || "new", amount, ledger, dr, cr]
      else
        "#<Entry[new]>"
      end
    end

    def inverse
      self.class.new(amount:, entry_type: type.inverse)
    end

    def type
      entry_type
    end
  end
end
