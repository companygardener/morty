class MultipleLedgersAccountant < Morty::Accountant
  balance :accruing, %w[principal]
  balance :varying,  %w[principal]

  daily do
    activity :interest, today
  end

  daily_guard do
    true
  end

  ledger :aggressive do
    balance :accruing, %w[principal]
    balance  :varying, %w[principal cash]

    activity :issue do
      entry :principal, :cash, amount
    end

    activity :payment do
      waterfall amount, limit: :cr, complete: true, entries: <<~END
        cash interest
        cash principal
        cash payable
      END
    end

    activity :interest do
      entry :interest, :revenue, accountant.rate_for(activity.effective_date).daily * balances[:accruing] * 10
    end
  end

  ledger :default do
    activity :issue do
      entry :principal, :cash, amount
    end

    activity :payment do
      waterfall amount, limit: :cr, complete: true, entries: <<~END
        cash interest
        cash principal
        cash payable
      END
    end

    activity :interest do
      entry :interest, :revenue, accountant.rate_for(activity.effective_date).daily * balances[:accruing]
    end
  end
end
