module Morty
  module Context
    class Simulation
      attr_reader :accountant

      def initialize(accountant)
        @accountant = accountant
      end

      # the "_" argument is to match the arity of Accountant#activity
      def finish(date, _ = nil)
        date = date.to_date

        accountant.simulate_today
        accountant.tomorrow while accountant.date < date
      end

      ActivityType.pluck(:name).each do |type|
        define_method(type) do |date, amount|
          finish date
          accountant.activity type, date, amount
        end
      end
    end
  end
end
