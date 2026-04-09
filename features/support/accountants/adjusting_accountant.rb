class AdjustingAccountant < Morty::Accountant
  balance :accruing, %w[principal]

  activity :issue do
    entry :principal, :cash, amount
  end

  activity :interest do
    if rate = accountant.rate_for(accountant.date.yesterday)
      amount ||= (rate.daily_for(accountant.date.yesterday) * balances[:accruing]).floor(2)

      entry :interest, :revenue, amount
    end
  end

  activity :late_fee do
    entry :late_fee, :late_fee_revenue, amount
  end

  waterfall :payment, limit: :cr, complete: true, entries: <<~END
    cash late_fee
    cash interest
    cash principal
    cash payable
  END

  daily do
    activity :interest, accountant.date.yesterday
  end

  daily_guard do
    accountant.activities.with_type(:interest).none? { |a| a.effective_date == accountant.date.yesterday }
  end
end
