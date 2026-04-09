require "spec_helper"

RSpec.describe Morty::List::Activity do
  let(:today) { Date.current }
  let(:activities) do
    [
      build_activity(type: :issue, effective_date: today - 2, accounting_date: today),
      build_activity(type: :payment, effective_date: today - 1, accounting_date: today),
      build_activity(type: :interest, effective_date: today, accounting_date: today)
    ]
  end

  describe "initialization" do
    it "from an Array" do
      list = described_class.new(activities)
      expect(list.size).to eq 3
    end

    it "from another List::Activity" do
      original = described_class.new(activities)
      copy = described_class.new(original)
      expect(copy.size).to eq 3
    end

    it "raises Morty::Error for invalid input" do
      expect { described_class.new("bad") }.to raise_error(Morty::Error)
      expect { described_class.new(123) }.to raise_error(Morty::Error)
    end
  end

  describe "#between" do
    subject { described_class.new(activities) }

    it "filters by effective_date" do
      result = subject.between(today - 2, today - 1)
      expect(result.size).to eq 2
    end

    it "filters by accounting_date when requested" do
      result = subject.between(today, today, by_accounting_date: true)
      expect(result.size).to eq 3
    end

    it "returns a List::Activity" do
      expect(subject.between(today, today)).to be_a(described_class)
    end
  end

  describe "#push" do
    it "adds an activity that has entries" do
      activity = create_activity_with_entries!
      list = described_class.new([])
      list.push(activity)
      expect(list.size).to eq 1
    end

    it "skips an activity with no entries" do
      activity = build_activity
      list = described_class.new([])
      list.push(activity)
      expect(list.size).to eq 0
    end
  end

  describe "#select and #reject" do
    subject { described_class.new(activities) }

    it "#select returns a List::Activity" do
      result = subject.select { |a| a.type?(:issue) }
      expect(result).to be_a(described_class)
      expect(result.size).to eq 1
    end

    it "#reject returns a List::Activity" do
      result = subject.reject { |a| a.type?(:issue) }
      expect(result).to be_a(described_class)
      expect(result.size).to eq 2
    end
  end

  describe "#count_by_type" do
    subject { described_class.new(activities) }

    it "returns a hash of type => count" do
      counts = subject.count_by_type
      expect(counts[:issue]).to eq 1
      expect(counts[:payment]).to eq 1
      expect(counts[:interest]).to eq 1
    end
  end

  describe "#with_type" do
    subject { described_class.new(activities) }

    it "filters by activity type" do
      result = subject.with_type(:issue)
      expect(result).to be_a(described_class)
      expect(result.size).to eq 1
      expect(result.first.type).to eq :issue
    end

    it "returns empty list for non-matching type" do
      result = subject.with_type(:cancel)
      expect(result.size).to eq 0
    end
  end

  describe "#by_type" do
    subject { described_class.new(activities) }

    it "returns a hash of type => array of activities" do
      grouped = subject.by_type
      expect(grouped[:issue].size).to eq 1
      expect(grouped[:issue].first.type).to eq :issue
    end
  end
end
