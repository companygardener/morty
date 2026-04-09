require "spec_helper"

RSpec.describe Morty::Diff do
  describe Morty::Diff::Sum do
    let(:entry_type) { Morty::EntryType.find_by_accounts(:cash, :principal) }

    def activity_with_entry(amount)
      activity = build_activity(amount: amount)
      activity.entries.build(entry_type: entry_type, amount: amount)
      activity
    end

    describe "#calculate" do
      it "aggregates entries by type" do
        activities = [activity_with_entry("100.00".to_d), activity_with_entry("50.00".to_d)]
        sum = described_class.new(activities)
        result = sum.calculate

        expect(result[entry_type]).to eq "150.00".to_d
      end

      it "is memoized" do
        sum = described_class.new([activity_with_entry("10.00".to_d)])
        expect(sum.calculate).to equal(sum.calculate)
      end
    end

    describe "#-" do
      it "subtracts another Sum producing net differences" do
        a = described_class.new([activity_with_entry("100.00".to_d)])
        b = described_class.new([activity_with_entry("60.00".to_d)])

        result = a - b

        expect(result[entry_type]).to eq "40.00".to_d
      end

      it "produces inverse type when result is negative" do
        a = described_class.new([activity_with_entry("30.00".to_d)])
        b = described_class.new([activity_with_entry("80.00".to_d)])

        result = a - b
        inverse = entry_type.inverse

        expect(result[inverse]).to eq "50.00".to_d
        expect(result).not_to have_key(entry_type)
      end
    end

    describe "#reduce" do
      it "removes zero entries" do
        sum = described_class.new([])
        result = sum.reduce({ entry_type => 0.to_d })
        expect(result).to be_empty
      end
    end
  end

  describe "Diff" do
    def make_accountant_stub(activities)
      list = Morty::List::Activity.new(activities)
      double("accountant", activities: list)
    end

    describe "#original?" do
      it "returns true for activities in the original set" do
        activity = build_activity
        original = make_accountant_stub([activity])
        adjusted = make_accountant_stub([activity])

        diff = described_class.new(original, adjusted)
        expect(diff.original?(activity)).to be true
      end

      it "returns false for activities not in the original" do
        a = build_activity(type: :issue)
        b = build_activity(type: :payment)
        original = make_accountant_stub([a])
        adjusted = make_accountant_stub([b])

        diff = described_class.new(original, adjusted)
        expect(diff.original?(b)).to be false
      end
    end

    describe "#additional" do
      it "returns adjusted activities not in original, excluding interest" do
        original_activity = build_activity(type: :issue)
        new_activity = build_activity(type: :payment)
        interest_activity = build_activity(type: :interest)

        original = make_accountant_stub([original_activity])
        adjusted = make_accountant_stub([original_activity, new_activity, interest_activity])

        diff = described_class.new(original, adjusted)
        additional = diff.additional

        expect(additional.map(&:type)).to eq [:payment]
      end
    end
  end
end
