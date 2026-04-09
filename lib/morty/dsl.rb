module Morty
  # DSL for defining Accountants.
  #
  # @example
  #   class Accountant < Morty::Accountant
  #     source :customer
  #
  #     activity :sale do |amount|
  #       entry :cash, :revenue, amount
  #     end
  #   end
  #
  #   Accountant.new(source: customer, start_date: Date.current)
  module DSL
    def self.extended(klass)
      klass.class_attribute :activity_procs
      klass.class_attribute :balances_list
      klass.class_attribute :daily_proc
      klass.class_attribute :daily_guard_proc
      klass.class_attribute :ledgers
      klass.class_attribute :source_name

      klass.activity_procs = Hash.new { |hash, key| hash[key] = {} }
      klass.balances_list  = Hash.new { |hash, key| hash[key] = {} }
      klass.ledgers        = [:default]
    end

    def activity(name, &block)
      raise Error, "missing block" unless block_given?

      activity_procs[current_ledger][name] = block
    end

    def balance(name, accounts)
      balances_list[current_ledger][name.to_sym] = accounts.map(&:to_sym)
    end

    def current_ledger
      @ledger || :default
    end

    def daily(&block)
      raise Error, "missing block" unless block_given?

      self.daily_proc = block
    end

    def daily_guard(&block)
      self.daily_guard_proc = block
    end

    # define activities scoped to a given ledger
    def ledger(name, &block)
      raise Error, "missing block" unless block_given?

      @ledger = name.to_sym

      self.ledgers |= [name]

      instance_exec(&block)
    ensure
      @ledger = nil
    end

    def source(name)
      name = name.to_sym

      raise Error, "invalid source: #{name} method already defined in #{self}" if instance_methods.include?(name)

      klass = name.to_s.classify.safe_constantize
      raise Error, "invalid source: #{name}"             unless klass
      raise Error, "invalid source: #{name} missing #id" unless klass.instance_methods.include?(:id)

      define_method(name) { source }

      self.source_name = name
    end

    # define an activity that uses a waterfall
    def waterfall(name, **kwargs)
      activity name do
        waterfall amount, **kwargs
      end
    end
  end
end
