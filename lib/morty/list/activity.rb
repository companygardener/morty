module Morty
  module List
    class Activity
      include Enumerable

      attr_reader :list

      delegate_missing_to :@list

      def initialize(obj)
        case obj
        when self.class             then @list = obj.list
        when Array                  then @list = obj
        when ActiveRecord::Relation then @list = obj.to_a
        else raise Error
        end
      end

      def between(start, finish, by_accounting_date: false)
        range = start.to_date .. finish.to_date

        if by_accounting_date
          select { |a| range.cover?(a.accounting_date) }
        else
          select { |a| range.cover?(a.effective_date)  }
        end
      end

      def by_type
        group_by(&:type)
      end

      def count_by_type
        by_type.transform_values(&:size)
      end

      def each(&block) = list.each(&block)

      def push(activity)
        return if activity.entries.none?

        list << activity
      end

      def reject(&block) = self.class.new list.reject(&block)
      def select(&block) = self.class.new list.select(&block)

      def sum_by_account
        Morty::Account.sum_over_activities list.map(&:id)
      end

      def with_type(type)
        self.class.new(select { |a| a.activity_type?(type.to_sym) })
      end
    end
  end
end
