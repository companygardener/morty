require "spec_helper"

RSpec.describe Morty::Schedule do
  let(:accountant) { double("accountant") }

  describe "initialization" do
    it "with nil creates empty events" do
      schedule = described_class.new(accountant, nil)
      expect(schedule.events).to eq []
    end

    it "with an array of hashes wraps each as Event" do
      events = [
        { amount: 100.to_d, date: Date.new(2026, 1, 5), type: :payment },
        { amount: 50.to_d,  date: Date.new(2026, 1, 10), type: :payment }
      ]
      schedule = described_class.new(accountant, events)
      expect(schedule.events.size).to eq 2
      expect(schedule.events).to all(be_a(Morty::Event))
    end

    it "with another Schedule copies events" do
      original = described_class.new(accountant, [{ amount: 100.to_d, date: Date.new(2026, 1, 5), type: :payment }])
      copy = described_class.new(accountant, original)
      expect(copy.events.size).to eq 1
      expect(copy.events.first).to be_a(Morty::Event)
    end

    it "with invalid input leaves events nil" do
      schedule = described_class.new(accountant, "bad")
      expect(schedule.events).to be_nil
    end
  end

  describe "#<<" do
    it "appends events from an array" do
      schedule = described_class.new(accountant, nil)
      schedule << [{ amount: 100.to_d, date: Date.new(2026, 1, 5), type: :payment }]
      expect(schedule.events.size).to eq 1
    end
  end

  describe "#between" do
    let(:events) do
      [
        { amount: 100.to_d, date: Date.new(2026, 1, 1), type: :issue },
        { amount: 50.to_d,  date: Date.new(2026, 1, 5), type: :payment },
        { amount: 25.to_d,  date: Date.new(2026, 1, 10), type: :payment }
      ]
    end
    let(:schedule) { described_class.new(accountant, events) }

    it "returns events within the date range" do
      result = schedule.between(Date.new(2026, 1, 3), Date.new(2026, 1, 7))
      expect(result.size).to eq 1
      expect(result.first.amount).to eq 50.to_d
    end

    it "returns empty when no events match" do
      result = schedule.between(Date.new(2026, 2, 1), Date.new(2026, 2, 28))
      expect(result).to be_empty
    end

    it "includes boundary dates" do
      result = schedule.between(Date.new(2026, 1, 1), Date.new(2026, 1, 10))
      expect(result.size).to eq 3
    end
  end

  describe "#for" do
    let(:schedule) do
      described_class.new(accountant, [
        { amount: 100.to_d, date: Date.new(2026, 1, 5), type: :payment },
        { amount: 50.to_d,  date: Date.new(2026, 1, 5), type: :refund }
      ])
    end

    it "returns events matching the exact date" do
      result = schedule.for(Date.new(2026, 1, 5))
      expect(result.size).to eq 2
    end

    it "returns empty for non-matching date" do
      result = schedule.for(Date.new(2026, 1, 6))
      expect(result).to be_empty
    end
  end

  describe "Enumerable" do
    let(:schedule) do
      described_class.new(accountant, [
        { amount: 100.to_d, date: Date.new(2026, 1, 1), type: :issue },
        { amount: 50.to_d,  date: Date.new(2026, 1, 5), type: :payment }
      ])
    end

    it "supports map" do
      amounts = schedule.map(&:amount)
      expect(amounts).to eq [100.to_d, 50.to_d]
    end

    it "supports count" do
      expect(schedule.count).to eq 2
    end
  end
end
