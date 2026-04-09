require "spec_helper"

RSpec.describe Morty::Account do
  describe ".sum_over_activities" do
    it "returns empty hash for empty array" do
      expect(described_class.sum_over_activities([])).to eq({})
    end

    it "returns account balances for valid activity ids" do
      activity = create_activity_with_entries!(amount: "250.00".to_d, dr: :cash, cr: :principal)
      result = described_class.sum_over_activities([activity.id])

      expect(result[:cash]).to eq "250.00".to_d
      expect(result[:principal]).to eq "-250.00".to_d
    end
  end

  describe ".sum_by_source" do
    let(:source) { TestHelpers::SourceStub.new(77777) }

    it "with effective_date returns balances grouped by ledger" do
      create_activity_with_entries!(source_id: source.id, amount: "100.00".to_d)
      result = described_class.sum_by_source(source, effective_date: Date.current)

      expect(result).to be_a(Hash)
      expect(result[:default][:cash]).to eq "100.00".to_d
    end

    it "with accounting_date returns balances" do
      create_activity_with_entries!(source_id: source.id, amount: "100.00".to_d)
      result = described_class.sum_by_source(source, accounting_date: Date.current)

      expect(result[:default][:cash]).to eq "100.00".to_d
    end

    it "raises when both effective_date and accounting_date given" do
      expect {
        described_class.sum_by_source(source, effective_date: Date.current, accounting_date: Date.current)
      }.to raise_error(RuntimeError, /pick one/)
    end

    it "raises when neither effective_date nor accounting_date given" do
      expect {
        described_class.sum_by_source(source)
      }.to raise_error(RuntimeError, /pick one/)
    end
  end
end
