class DailyAccountant < Morty::Accountant
  daily do
    activity :interest, today, "1.00"
  end

  daily_guard do
    today != Date.today + 1
  end

  activity :interest do
    entry :interest, :revenue, amount
  end
end
