class SimulatingAccountant < Morty::Accountant
  balance :accruing, %w[principal]

  activity :issue do
    entry :principal, :cash, amount
  end

  waterfall :payment, limit: :cr, complete: true, entries: <<~END
    cash late_fee
    cash interest
    cash principal
    cash payable
  END

  activity :interest do
    if rate = accountant.rate_for(accountant.date.yesterday)
      amount ||= (rate.daily_for(accountant.date.yesterday) * balances[:accruing]).floor(2)

      entry :interest, :revenue, amount
    end
  end

  activity :late_fee do
    entry :late_fee, :late_fee_revenue, amount
  end

  daily do
    activity :interest, today
  end

  daily_guard do
    accountant.activities.none? do |activity|
      activity.effective_date == accountant.date && activity.type?(:interest)
    end
  end
end
