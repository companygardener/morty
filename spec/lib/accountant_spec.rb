require "spec_helper"

# Minimal accountant subclass for unit testing
class TestAccountant < Morty::Accountant
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

  balance :accruing, %w[principal]

  activity :interest do
    if rate = accountant.rate_for(accountant.date.yesterday)
      amount ||= (rate.daily_for(accountant.date.yesterday) * balances[:accruing]).floor(2)
      entry :interest, :revenue, amount
    end
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

RSpec.describe Morty::Accountant do
  let(:source) { TestHelpers::SourceStub.new(88888) }

  def setup_accountant(rates: { Date.new(2020, 1, 1) => "0.365" })
    acc = TestAccountant.new
    acc.rates = rates
    acc.source = source
    acc.start_date = Date.current
    acc
  end

  describe "#source=" do
    it "wraps a plain object in Source" do
      acc = TestAccountant.new
      acc.source = source
      expect(acc.source).to be_a(Morty::Source)
    end

    it "accepts an existing Source without re-wrapping" do
      acc = TestAccountant.new
      wrapped = Morty::Source.new(source)
      acc.source = wrapped
      expect(acc.source).to equal(wrapped)
    end

    it "raises when setting source twice" do
      acc = TestAccountant.new
      acc.source = source
      expect { acc.source = TestHelpers::SourceStub.new(2) }.to raise_error(Morty::Error, /multiple sources/)
    end

    it "ignores nil" do
      acc = TestAccountant.new
      acc.source = nil
      expect(acc.source).to be_nil
    end
  end

  describe "#rates=" do
    it "sets rates from a hash" do
      acc = TestAccountant.new
      acc.rates = { Date.new(2020, 1, 1) => "0.10" }
      expect(acc.rates).to be_a(Hash)
    end

    it "raises when setting rates twice" do
      acc = TestAccountant.new
      acc.rates = { Date.new(2020, 1, 1) => "0.10" }
      expect { acc.rates = { Date.new(2020, 1, 1) => "0.20" } }.to raise_error(Morty::Error, /rates already set/)
    end
  end

  describe "#start_date=" do
    it "raises for invalid date" do
      acc = TestAccountant.new
      acc.rates = { Date.new(2020, 1, 1) => "0.10" }
      acc.source = source
      expect { acc.start_date = 12345 }.to raise_error(Morty::Error, /invalid date/)
    end

    it "raises when set twice" do
      acc = setup_accountant
      expect { acc.start_date = Date.current }.to raise_error(Morty::Error, /start_date already set/)
    end

    it "raises for future start_date" do
      acc = TestAccountant.new
      acc.rates = { Date.new(2020, 1, 1) => "0.10" }
      acc.source = source
      expect { acc.start_date = Date.current + 1 }.to raise_error(Morty::Error, /future/)
    end
  end

  describe "#check_setup" do
    it "raises when source is missing" do
      acc = TestAccountant.new
      expect { acc.send(:check_setup) }.to raise_error(Morty::Error, /missing source/)
    end

    it "raises when start_date is missing" do
      acc = TestAccountant.new
      acc.source = source
      expect { acc.send(:check_setup) }.to raise_error(Morty::Error, /missing start_date/)
    end
  end

  describe "#rate_for" do
    it "finds the effective rate for a date" do
      acc = setup_accountant(rates: {
        Date.new(2020, 1, 1) => "0.05",
        Date.new(2023, 6, 1) => "0.10"
      })

      expect(acc.rate_for(Date.new(2024, 1, 1)).yearly).to eq "0.10".to_d
      expect(acc.rate_for(Date.new(2021, 1, 1)).yearly).to eq "0.05".to_d
    end

    it "returns nil when no rate matches" do
      acc = setup_accountant(rates: { Date.new(2025, 6, 1) => "0.05" })
      expect(acc.rate_for(Date.new(2020, 1, 1))).to be_nil
    end
  end

  describe "#activity" do
    it "records an activity and applies it to books" do
      acc = setup_accountant
      acc.activity(:issue, Date.current, "500.00".to_d)

      expect(acc.activities.size).to eq 1
      expect(acc.accounts[:principal]).to eq "500.00".to_d
      expect(acc.accounts[:cash]).to eq "-500.00".to_d
    end

    it "raises for missing activity type" do
      acc = setup_accountant
      expect { acc.activity(:nonexistent, Date.current, "100.00".to_d) }.to raise_error(LookupBy::Error)
    end
  end

  describe "#save" do
    it "persists activities to the database" do
      acc = setup_accountant
      acc.activity(:issue, Date.current, "100.00".to_d)
      acc.save

      expect(Morty::Activity.where(source_id: source.id).count).to eq 1
    end

    it "raises when source is missing" do
      acc = TestAccountant.new
      expect { acc.save }.to raise_error(Morty::Error, /missing source/)
    end
  end

  describe "#simulate_today" do
    it "runs daily and daily_schedule" do
      acc = setup_accountant
      acc.activity(:issue, Date.current, "1000.00".to_d)
      acc.simulate_today

      expect(acc.activities.count_by_type[:interest]).to eq 1
    end

    it "does not run twice for the same date" do
      acc = setup_accountant
      acc.activity(:issue, Date.current, "1000.00".to_d)
      acc.simulate_today
      acc.simulate_today

      expect(acc.activities.count_by_type[:interest]).to eq 1
    end
  end

  describe "#tomorrow" do
    it "advances the date and simulates" do
      acc = setup_accountant
      acc.activity(:issue, Date.current, "1000.00".to_d)

      original_date = acc.date
      acc.tomorrow

      expect(acc.date).to eq original_date + 1
    end
  end

  describe "#balances" do
    it "returns named balance sums from the default book" do
      acc = setup_accountant
      acc.activity(:issue, Date.current, "500.00".to_d)

      expect(acc.balances[:accruing]).to eq "500.00".to_d
    end
  end

  describe "#schedule=" do
    it "accepts a Schedule" do
      acc = TestAccountant.new
      schedule = Morty::Schedule.new(acc, [{ amount: 100.to_d, date: Date.current, type: :payment }])
      acc.schedule = schedule
      expect(acc.schedule).to be_a(Morty::Schedule)
    end

    it "wraps an array in a Schedule" do
      acc = TestAccountant.new
      acc.schedule = [{ amount: 100.to_d, date: Date.current, type: :payment }]
      expect(acc.schedule).to be_a(Morty::Schedule)
    end
  end

  describe "#apply" do
    it "applies activities to books and adds to activity list" do
      acc = setup_accountant
      activity = create_activity_with_entries!(source_id: source.id, amount: "200.00".to_d)
      acc.apply(activity)

      expect(acc.activities.size).to eq 1
      expect(acc.accounts[:cash]).to eq "200.00".to_d
    end
  end
end
