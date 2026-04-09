require "spec_helper"

RSpec.describe Morty::Entry do
  let(:entry_type) { Morty::EntryType.find_by_accounts(:cash, :principal) }

  describe "#type" do
    it "aliases entry_type" do
      entry = described_class.new(entry_type: entry_type, amount: "100.00".to_d)
      expect(entry.type).to eq entry_type
    end
  end

  describe "#inverse" do
    it "creates a new Entry with inverse entry_type and same amount" do
      entry = described_class.new(entry_type: entry_type, amount: "100.00".to_d)
      inverse = entry.inverse

      expect(inverse).to be_a(described_class)
      expect(inverse.amount).to eq "100.00".to_d
      expect(inverse.entry_type.dr).to eq entry_type.cr
      expect(inverse.entry_type.cr).to eq entry_type.dr
    end

    it "returns an unsaved record" do
      entry = described_class.new(entry_type: entry_type, amount: "50.00".to_d)
      expect(entry.inverse).not_to be_persisted
    end
  end

  describe "#inspect" do
    it "with a type shows formatted string" do
      entry = described_class.new(entry_type: entry_type, amount: "100.00".to_d)
      expect(entry.inspect).to match(/Entry\[new\] \$100\.00 default DR\[cash\] CR\[principal\]/)
    end

    it "without a type shows minimal string" do
      entry = described_class.new(amount: "100.00".to_d)
      expect(entry.inspect).to eq "#<Entry[new]>"
    end
  end
end
