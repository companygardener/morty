require "colorize"

module Morty
  class Activity < ApplicationRecord
    lookup_for :activity_type, symbolize: true

    alias_attribute :amount, :activity_amount

    # AR doesn't support alias_attribute for associations, so we have to do it manually
    alias_method :type,  :activity_type
    alias_method :type=, :activity_type=
    alias_method :type?, :activity_type?

    belongs_to :cancels, class_name: "Activity", optional: true

    has_one :cancelled_by, class_name: "Activity", foreign_key: :cancels_id

    has_many :entries

    default_scope -> { includes(:cancelled_by, :entries) }

    scope :until,       ->(date)   { where("effective_date <= ?", date) }
    scope :with_source, ->(source) { where(source_id: source.id) }
    scope :with_type,   ->(type)   { where(activity_type: type) }

    after_initialize do
      self.effective_date ||= accounting_date
    end

    def ==(other)
      other.class          == self.class     &&
      (id.nil? || other.id.nil? || other.id == id) &&
      other.source_id      == source_id      &&

      other.type           == type           &&
      other.effective_date == effective_date &&
      other.amount         == amount
    end

    def cancel(date, type)
      build_cancelled_by(type: type) do |a|
        a.source_id       = source_id
        a.accounting_date = date
        a.effective_date  = effective_date
        a.amount          = amount
        a.entries         = entries.map(&:inverse)
        a.cancels         = self
      end
    end

    def reverse(date, type)
      self.class.new(type: type) do |a|
        a.source_id       = source_id
        a.accounting_date = date
        a.entries         = entries.map(&:inverse)
      end
    end

    def cancelled?
      !! cancelled_by
    end

    def cancelling?
      cancels? || cancelled?
    end

    def cancels?
      !! cancels_id || cancels
    end

    def retroactive?
      effective_date < accounting_date
    end

    # belongs_to lite
    def source=(obj)
      self.source_id = obj.id
    end

    def to_event
      { amount: amount, date: effective_date, type: type }
    end

    def debug(ledger = :default)
      result = "\n"

      header = type.to_s.humanize
      header << " $%.2f" % amount if amount
      header << " %s\n" % accounting_date

      result << header.blue

      result << "\nEffective on %s" % effective_date unless accounting_date == effective_date

      # entries.with_ledger(ledger)
      list = entries.select { |e| e.ledger == ledger }

      if list.any?
        max = Account.pluck(:account).map(&:length).max

        result << "\n#{ledger.to_s.humanize.yellow} ledger entries\n"
        result << "\n"
        result << " " * max + "  |        DR |       CR \n"
        result << "-" * max + "--|-----------|----------\n"

        amounts = Hash.new(0)

        list.each do |entry|
          amounts[entry.type.dr] += entry.amount
          amounts[entry.type.cr] -= entry.amount
        end

        amounts.each do |account, amount|
          if amount > 0
            result << " %#{max}s | %9.2f |\n"      % [account, amount]
          else
            result << " %#{max}s |           | %9.2f\n" % [account, -amount]
          end
        end
      else
        result << "\n#{ledger.to_s.humanize} ledger has no entries\n".yellow
      end

      result << "\n"

      puts result
    end

    def inspect
      result = "#<Activity%-10s " % "[#{id || "new"}]"

      result << (amount ? "$%8.2f" % amount : " %8s" % "")

      result << " #{accounting_date}" if accounting_date

      if effective_date != accounting_date
        result << " #{effective_date}"
      else
        result << "           "
      end

      result << " #{type}" if type
      result << ">"
      result
    end
  end
end
