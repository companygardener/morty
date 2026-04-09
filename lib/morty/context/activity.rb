module Morty
  module Context
    class Activity
      attr_reader :accountant, :activity, :book

      delegate :rates, :source,      to: :accountant
      delegate :accounts, :balances, to: :book
      delegate :amount,              to: :activity

      def initialize(book, activity)
        @accountant = book.accountant
        @activity   = activity
        @book       = book

        define_singleton_method(accountant.source_name) { source } if accountant.source_name
      end

      def entry(dr, cr, amount)
        book.entry(dr, cr, amount, activity: activity)
      end

      def waterfall(amount, limit: nil, complete: false, entries:)
        remaining = amount

        limit = limit.try :to_sym

        list = entries.split.map(&:to_sym).each_slice(2)

        last = list.size

        list.with_index(1) do |(dr, cr), i|
          limit = nil if complete && i == last

          amount = case limit
                   when :dr
                     accounts.key?(dr) ? [remaining, accounts[dr].abs].min : 0.to_d
                   when :cr
                     accounts.key?(cr) ? [remaining, accounts[cr].abs].min : 0.to_d
                   else
                     remaining
                   end

          entry dr, cr, amount

          remaining -= amount

          break if remaining.zero?
        end
      end
    end
  end
end
