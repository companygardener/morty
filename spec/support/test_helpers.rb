module TestHelpers
  SourceStub = Struct.new(:id)

  def build_activity(type: :issue, source_id: 1, accounting_date: Date.current, effective_date: nil, amount: "100.00".to_d)
    Morty::Activity.new(
      activity_type: type,
      source_id: source_id,
      accounting_date: accounting_date,
      effective_date: effective_date || accounting_date,
      activity_amount: amount
    )
  end

  def create_activity_with_entries!(type: :issue, source_id: 1, accounting_date: Date.current, amount: "100.00".to_d, dr: :cash, cr: :principal)
    activity = build_activity(type: type, source_id: source_id, accounting_date: accounting_date, amount: amount)
    entry_type = Morty::EntryType.find_by_accounts(dr, cr)
    activity.entries.build(entry_type: entry_type, amount: amount)
    activity.save!
    activity
  end
end

RSpec.configure do |config|
  config.include TestHelpers
end
