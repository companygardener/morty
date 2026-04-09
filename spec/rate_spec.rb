require "spec_helper"

RSpec.describe Morty::Rate do
  context "when annual rate is 0.365" do
    subject { Morty::Rate.new("0.365") }

    its(:yearly)     { is_expected.to eq '0.36500000'.to_d }
    its(:monthly)    { is_expected.to eq '0.03041667'.to_d }
    its(:daily)      { is_expected.to eq '0.00100000'.to_d }
    its(:daily_leap) { is_expected.to eq '0.00099727'.to_d }

    describe "#daily_for" do
      it 'should use a 365 day year for 2025-12-31' do
        expect(subject.daily_for("2025-12-31".to_date)).to eq subject.daily
      end

      it "should use a 366 day year for 2028-01-01" do
        expect(subject.daily_for("2028-01-01".to_date)).to eq subject.daily_leap
      end
    end
  end

  context "when constructed from another Rate" do
    let(:original) { described_class.new("0.12") }
    subject { described_class.new(original) }

    it "preserves the yearly value" do
      expect(subject.yearly).to eq original.yearly
    end

    it "preserves daily precision" do
      expect(subject.daily).to eq original.daily
    end
  end

  context "when rate is zero" do
    subject { described_class.new("0") }

    its(:yearly)     { is_expected.to eq 0.to_d }
    its(:monthly)    { is_expected.to eq 0.to_d }
    its(:daily)      { is_expected.to eq 0.to_d }
    its(:daily_leap) { is_expected.to eq 0.to_d }
  end

  describe "#<=>" do
    let(:low)  { described_class.new("0.05") }
    let(:high) { described_class.new("0.15") }

    it "compares two Rates" do
      expect(low).to be < high
      expect(high).to be > low
    end

    it "compares equal Rates" do
      expect(described_class.new("0.10")).to eq described_class.new("0.10")
    end

    it "compares Rate with a numeric" do
      rate = described_class.new("0.10")
      expect(rate).to eq "0.10".to_d
    end

    it "enables sorting" do
      rates = [high, low]
      expect(rates.sort.map(&:yearly)).to eq [low.yearly, high.yearly]
    end
  end

  describe "#to_d" do
    it "returns the yearly rate as BigDecimal" do
      rate = described_class.new("0.05")
      expect(rate.to_d).to be_a(BigDecimal)
      expect(rate.to_d).to eq "0.05".to_d
    end
  end

  describe "#to_s" do
    it "returns a formatted string" do
      rate = described_class.new("0.125")
      expect(rate.to_s).to eq "0.12"
    end
  end
end
