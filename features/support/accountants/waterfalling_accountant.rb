class WaterfallingAccountant < Morty::Accountant
  activity :issue do
    entry :receivable, :cash, amount
  end

  waterfall :payment, limit: :cr, complete: true, entries: <<~END
    cash receivable
    cash payable
  END

  waterfall :refund, limit: :dr, complete: true, entries: <<~END
    payable    cash
    receivable cash
  END
end
