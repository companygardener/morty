module Morty
  class Account < ApplicationRecord
    lookup_by :account, cache: true

    lookup_for :account_type, class_name: AccountType

    def self.sum_over_activities(activity_ids)
      return {} if activity_ids.empty?

      rows = connection.select_all(sanitize_sql_array([
        "SELECT account, SUM(amount) AS balance FROM morty.details WHERE activity_id IN (?) GROUP BY account",
        activity_ids
      ]))

      rows.each_with_object({}) do |row, hash|
        hash[row["account"].to_sym] = row["balance"].to_d
      end
    end

    def self.sum_by_source(source, effective_date: nil, accounting_date: nil)
      raise "pick one: effective_date or accounting_date" unless effective_date || accounting_date
      raise "pick one: effective_date or accounting_date" if effective_date && accounting_date

      date_col = effective_date ? "effective_date" : "accounting_date"
      date_val = effective_date || accounting_date

      rows = connection.select_all(sanitize_sql_array([
        "SELECT ledger, account, SUM(amount) AS balance FROM morty.details WHERE source_id = ? AND #{date_col} <= ? GROUP BY ledger, account",
        source.id, date_val
      ]))

      rows.each_with_object(Hash.new { |h, k| h[k] = {} }) do |row, hash|
        hash[row["ledger"].to_sym][row["account"].to_sym] = row["balance"].to_d
      end
    end
  end
end
