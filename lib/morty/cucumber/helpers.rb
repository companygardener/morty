module Morty::Cucumber::Helpers
  def accountant_class(type)
    "#{type.parameterize.underscore}_accountant".classify.constantize
  end

  def activities_from(table)
    table.raw.map do |row|
      type, *rest, amount = row

      {
        type: type.to_sym,
        date: rest.first&.to_date || Date.current,
        amount: amount.presence&.to_d
      }
    end
  end

  def activity_counts_from(table)
    table.raw.to_h { |type, count| [type.to_sym, count.to_i] }
  end

  def balances_from(table)
    table.raw.to_h { |account, amount| [account.to_sym, amount.presence&.to_d] }
  end
end

World(Morty::Cucumber::Helpers)
