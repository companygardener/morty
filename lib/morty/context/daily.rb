module Morty
  module Context
    class Daily
      attr_reader :accountant

      delegate_missing_to :@accountant

      def initialize(accountant)
        @accountant = accountant

        define_singleton_method(accountant.source_name) { source } if accountant.source_name
      end

      def today
        accountant.date
      end

      def rate
        rates.detect { |date, _| today >= date }&.last
      end
    end
  end
end
