require "bigdecimal"

module Morty
  # An Accountant manages a set of Books, each with its own Ledger and Account balances.
  #
  # Accounting for things correctly and efficiently is hard. Morty makes no warranties
  # about the correctness of its implementation, and it is up to you to ensure that your
  # implementation of the Accountant class is correct for your domain. Morty provides a set of
  # tools to help you do that, but it is your responsibility to use them correctly.
  #
  # If you use any class to manage the tables in the morty schema, other than the Accountant,
  # you do so at your own risk. The Accountant is the sole class be responsible for
  # creating and applying Activities, and for managing the balances of Accounts.
  #
  # Double-entry transactions (activities and entries)
  #
  #     Activity | DR        | CR        | Amount
  #     -----------------------------------------
  #     issue    | principal | cash      |  5000
  #     interest | interest  | cash      |    50
  #     payment  | cash      | interest  |    50
  #              | cash      | principal |   950
  #
  # Single-entry transactions (details view)
  #
  #    Activity | Account   | Amount
  #    --------------------------------
  #    issue    | principal |  5000
  #    interest | interest  |    50
  #    payment  | cash      | -1000
  #             | principal |  -950
  #             | interest  |   -50
  #
  # Some Martin Fowler ideas that could be useful
  #
  #     Accounting Patterns    https://martinfowler.com/apsupp/accounting.pdf
  #
  #     Retroactive Event      https://martinfowler.com/eaaDev/RetroactiveEvent.html
  #     Parallel Model         https://martinfowler.com/eaaDev/ParallelModel.html
  #     Temporal Object        https://martinfowler.com/eaaDev/TemporalObject.html
  #     Temporal Property      https://martinfowler.com/eaaDev/TemporalProperty.html
  #     Time Point             https://martinfowler.com/eaaDev/TimePoint.html
  #     Effectivity Period     https://martinfowler.com/eaaDev/Effectivity.html
  #     Snapshot               https://martinfowler.com/eaaDev/Snapshot.html
  #     Proposed Object        https://martinfowler.com/eaaDev/ProposedObject.html
  #     Audit Log              https://martinfowler.com/eaaDev/AuditLog.html
  #     Reversal Adjustment
  #     Difference Adjustment
  #     Posting Rule
  #
  # It implements these, in a very specific way
  #
  #     Account                https://martinfowler.com/eaaDev/Account.html
  #     Accounting Transaction https://martinfowler.com/eaaDev/AccountingTransaction.html
  #
  # We do not implement:
  #
  #     Replacement Adjustment
  #
  class Accountant
    # List::Activity
    attr_reader :activities

    attr_reader :books
    attr_reader :ledgers

    attr_reader :date

    attr_reader :rates

    attr_reader :schedule

    attr_reader :source
    attr_reader :source_name

    attr_reader :start_date

    attr_reader :simulated_to

    def self.inherited(base)
      base.extend DSL
    end

    def initialize
      @accounts = Hash.new { |hash, key| hash[key] = Hash.new { |h, k| h[k] = 0.to_d } }
      @books    = ledgers.to_h { |name| [name, Book.new(name, accountant: self)] }

      # default to an schedule
      @schedule = Schedule.new(self, nil)
    end

    def accounts(ledger = :default)
      @accounts[ledger.to_sym]
    end

    def activities=(list)
      @activities = List::Activity.new(list || [])

      @activities.each do |activity|
        books.each do |name, book|
          book.apply activity
        end
      end
    end

    def activity(type, date = nil, amount = nil, effective_date: nil, idempotent_uuid: nil)
      type   = type.to_sym
      date   = date.try(:to_date) || self.date
      amount = amount.try :to_d

      check_setup

      activity = build_activity(type) do |a|
        a.idempotent_uuid = idempotent_uuid

        a.accounting_date = date
        a.effective_date  = effective_date.try(:to_date) if effective_date
        a.amount          = amount
      end

      if activity.retroactive?
        adjust(effective_date, with: activity)
      else
        books.each do |name, book|
          raise "missing activity" unless activity_procs[name].key?(type)

          Context::Activity.new(book, activity).tap do |ctx|
            ctx.instance_exec(&activity_procs[name][type])
          end
        end

        activities.push activity
      end

      activity
    end

    # @return [Morty::Activity]
    def adjust(past_date, with: nil)
      Adjustment.new(self, past_date, date).adjust(with)
    end

    # @return [Morty::Accountant]
    def adjusting_accountant(**kwargs)
      options = { rates:, source:, schedule:, start_date: }.merge(kwargs.compact)

      self.class.new.tap do |adjusting|
        adjusting.rates      = options[:rates]
        adjusting.source     = options[:source]
        adjusting.schedule   = options[:schedule]
        adjusting.start_date = options[:start_date]
      end
    end

    # Apply a list of activities to the books
    def apply(list)
      Array(list).each do |activity|
        books.each do |name, book|
          book.apply activity
        end

        activities.push(activity)
      end

      list
    end

    def balances(ledger = :default)
      books[ledger.to_sym].balances
    end

    def build_activity(type, attributes = {})
      defaults = {
        accounting_date: date,
        source_id:       source.id,
        type:            type
      }

      Activity.new(defaults.merge(attributes)) do |activity|
        yield activity if block_given?
      end
    end

    # Cancel an activity
    #
    # @param incorrect [Morty::Activity] Activity to cancel
    #
    # @return [Morty::Activity] cancelling activity
    def cancel(incorrect, type = "cancel", idempotent_uuid: nil)
      activity = incorrect.cancel(date, type)

      activity.idempotent_uuid = idempotent_uuid

      idx = activities.index { |a| a.object_id == incorrect.object_id }       ||
        incorrect.persisted? && activities.index { |a| a.id == incorrect.id } ||
        activities.index(incorrect)

      activities[idx] = incorrect

      apply(activity)

      adjust(activity.effective_date)
      activity
    end

    def check_setup
      raise Error, "missing source"     unless source
      raise Error, "missing start_date" unless start_date
    end

    def daily(date = nil)
      return unless daily_proc

      @date = date.to_date if date

      ctx = Context::Daily.new(self)

      # A missing guard means the daily block should always run. This keeps
      # #cancel usable for accountants that only define activities — #cancel
      # routes through #adjust → #simulate_to → #daily and used to blow up
      # with LocalJumpError when daily_proc was nil.
      should_run = daily_guard_proc ? ctx.instance_exec(&daily_guard_proc) : true

      ctx.instance_exec(&daily_proc) if should_run
    end

    def daily_schedule
      schedule.for(date).each do |event|
        activity event.type, event.date, event.amount
      end

      @simulated_to = date
    end

    # @note dsl could expose a method to define a domain-specific synonym for "cancel"
    def return(incorrect, idempotent_uuid: nil)
      cancel(incorrect, "return", idempotent_uuid:)
    end

    def rates
      @rates.to_h
    end

    def rates=(list)
      raise Error, "rates already set" if @rates.present?

      @rates = list.to_h.map { |date, rate| [date.to_date, Rate.new(rate)] }.sort.reverse
    end

    def rate_for(date = self.start_date)
      @rates.detect { |eff_date, _| date >= eff_date }&.last
    end

    def reverse(prior_activity, type = "reversal")
      apply prior_activity.reverse(date, type)
    end

    def save
      raise Error, "missing source" unless source

      ApplicationRecord.transaction(requires_new: true) do
        activities.each(&:save!)
      end
    end

    def schedule=(list)
      @schedule = case list
                  when Schedule then list
                  else
                    Schedule.new(self, list)
                  end
    end

    def source=(obj)
      return unless obj

      raise Error, "multiple sources" if source

      # wrap the incoming object
      @source = obj.is_a?(Source) ? obj : Source.new(obj)
    end

    def start_date=(date)
      raise Error, "invalid date" unless date.respond_to?(:to_date)
      raise Error, "start_date already set" if start_date

      @date = @start_date = date.to_date

      raise Error, "future start_date" if start_date > Date.current

      load_activities
    end

    def simulate(&block)
      raise Error, "missing start_date" unless start_date

      Context::Simulation.new(self).tap do |ctx|
        ctx.instance_exec(&block) if block_given?
      end
    end

    def simulated?(date)
      return false unless simulated_to

      simulated_to >= date.to_date
    end

    def simulate_to(date)
      simulate { finish date.to_date }
    end

    def simulate_today
      return if simulated?(date)

      daily
      daily_schedule
    end

    def tomorrow
      simulate_today

      @date += 1

      simulate_today
    end

    private def load_activities
      check_setup

      self.activities = Activity.with_source(source).until(start_date)

      @simulated_to = activities.map(&:effective_date).max

      Account.sum_by_source(source, effective_date: start_date).each do |ledger, accounts|
        accounts.each do |account, balance|
          @accounts[ledger][account] = balance
        end
      end
    end
  end
end
