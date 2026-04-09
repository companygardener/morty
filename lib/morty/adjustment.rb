module Morty
  class Adjustment
    attr_reader :accountant

    def initialize(accountant, retroactive_date, accounting_date, excluded_activities: [])
      @accountant  = accountant

      @retroactive_date = retroactive_date
      @accounting_date  = accounting_date

      @excluded_activities = excluded_activities

      @min_date = accountant.activities.map(&:effective_date).min || retroactive_date
    end

    # @todo simplify this
    def adjust(activity)
      adjuster.simulate_to(@retroactive_date)

      if activity
        activity.entries = adjuster.activity(activity.type, activity.effective_date, activity.amount).entries
        accountant.apply(activity)
      end

      adjuster.simulate_to(@accounting_date)

      adjustment = adjuster.build_activity(:adjustment) do |a|
        a.entries = diff.entries
      end

      additional = diff.additional.to_a
      additional.each { |a| a.accounting_date = @accounting_date }

      accountant.apply additional
      accountant.apply adjustment

      activity
    end

    private def adjuster
      @adjuster ||= accountant.adjusting_accountant(**options)
    end

    private def diff
      @diff ||= Diff.new(accountant, adjuster)
    end

    private def options
      {
        schedule: schedule,
        start_date: @min_date - 1
      }
    end

    private def schedule
      accountant.activities.reject(&:cancelling?)
                           .reject { |a| a.type?(:interest) || a.type?(:adjustment) }
                           .reject { |a| @excluded_activities.include?(a) }
                           .between(@min_date, @accounting_date)
                           .list
                           .sort_by { |a| [a.effective_date, a.id || Float::INFINITY] }
    end
  end
end
