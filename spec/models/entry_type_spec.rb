require "spec_helper"

RSpec.describe Morty::EntryType do
  describe ".find_by_accounts" do
    it "finds the correct entry type for cash/principal" do
      type = described_class.find_by_accounts(:cash, :principal)
      expect(type).to be_present
      expect(type.dr).to eq :cash
      expect(type.cr).to eq :principal
      expect(type.ledger).to eq :default
    end

    it "returns nil for non-existent combination" do
      type = described_class.find_by_accounts(:cash, :cash)
      expect(type).to be_nil
    end

    it "respects ledger scoping" do
      default_type = described_class.find_by_accounts(:cash, :principal, :default)
      aggressive_type = described_class.find_by_accounts(:cash, :principal, :aggressive)

      expect(default_type).to be_present
      expect(aggressive_type).to be_present
      expect(default_type).not_to eq aggressive_type
    end
  end

  describe "#inverse" do
    it "returns entry type with dr/cr swapped on same ledger" do
      type = described_class.find_by_accounts(:cash, :principal)
      inverse = type.inverse

      expect(inverse.dr).to eq :principal
      expect(inverse.cr).to eq :cash
      expect(inverse.ledger).to eq type.ledger
    end

    it "round-trips: inverse of inverse returns original" do
      type = described_class.find_by_accounts(:cash, :principal)
      expect(type.inverse.inverse).to eq type
    end
  end
end
