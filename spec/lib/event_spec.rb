require "spec_helper"

RSpec.describe Morty::Event do
  describe "construction from Hash" do
    subject { described_class.new(amount: 100.to_d, date: Date.new(2026, 1, 1), type: :issue) }

    its(:amount) { is_expected.to eq 100.to_d }
    its(:date)   { is_expected.to eq Date.new(2026, 1, 1) }
    its(:type)   { is_expected.to eq :issue }
  end

  describe "construction from Hash with missing keys" do
    subject { described_class.new({}) }

    its(:amount) { is_expected.to be_nil }
    its(:date)   { is_expected.to be_nil }
    its(:type)   { is_expected.to be_nil }
  end

  describe "construction from another Event" do
    let(:original) { described_class.new(amount: 50.to_d, date: Date.current, type: :payment) }
    subject { described_class.new(original) }

    it "shares the same info hash (alias, not copy)" do
      expect(subject.info).to equal(original.info)
    end

    its(:amount) { is_expected.to eq 50.to_d }
  end

  describe "construction from an Activity" do
    let(:activity) { build_activity(type: :issue, amount: "200.00".to_d) }
    subject { described_class.new(activity) }

    its(:amount) { is_expected.to eq "200.00".to_d }
    its(:type)   { is_expected.to eq :issue }
    its(:date)   { is_expected.to eq activity.effective_date }
  end

  describe "invalid construction" do
    it "raises Morty::Error for a String" do
      expect { described_class.new("bad") }.to raise_error(Morty::Error)
    end

    it "raises Morty::Error for an Integer" do
      expect { described_class.new(42) }.to raise_error(Morty::Error)
    end

    it "raises Morty::Error for nil" do
      expect { described_class.new(nil) }.to raise_error(Morty::Error)
    end
  end
end
