class DefaultingAccountant < Morty::Accountant
  balance :accruing, %w[principal principal_late]

  activity :issue do
    entry :principal, :cash, amount
  end

  activity :interest do
    entry :interest, :revenue, amount
  end

  daily do
    activity :interest, today, rate.daily * balances[:accruing]
  end

  daily_guard do
    accountant.activities.with_type(:interest).none? { |a| a.effective_date == accountant.date }
  end

  waterfall :default, limit: :cr, entries: <<~END
    interest_late  interest
    principal_late principal
  END

  waterfall :payment, limit: :cr, complete: true, entries: <<~END
    cash interest_late
    cash principal_late
    cash interest
    cash principal
    cash payable
  END
end
