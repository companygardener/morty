require "spec_helper"

RSpec.describe Morty::Book do
  # Minimal accountant-like object for Book specs
  let(:accounts_hash) { Hash.new { |h, k| h[k] = 0.to_d } }
  let(:accountant) do
    double("accountant",
      accounts: accounts_hash,
      balances_list: { default: { total: [:cash, :principal] } }
    )
  end

  describe "initialization" do
    it "raises when ledger is nil" do
      expect { described_class.new(nil, accountant: accountant) }.to raise_error("missing ledger")
    end

    it "succeeds with a ledger" do
      book = described_class.new(:default, accountant: accountant)
      expect(book.ledger).to eq :default
    end
  end

  describe "#entry" do
    let(:book) { described_class.new(:default, accountant: accountant) }
    let(:activity) { build_activity }

    it "with positive amount creates and applies an entry" do
      entry = book.entry(:cash, :principal, "100.00".to_d, activity: activity)

      expect(entry).to be_a(Morty::Entry)
      expect(entry.amount).to eq "100.00".to_d
      expect(accounts_hash[:cash]).to eq "100.00".to_d
      expect(accounts_hash[:principal]).to eq "-100.00".to_d
    end

    it "with zero amount returns nil" do
      expect(book.entry(:cash, :principal, 0, activity: activity)).to be_nil
    end

    it "with nil amount returns nil" do
      expect(book.entry(:cash, :principal, nil, activity: activity)).to be_nil
    end

    it "with negative amount raises" do
      expect {
        book.entry(:cash, :principal, "-5.00".to_d, activity: activity)
      }.to raise_error("entry amount cannot be negative")
    end

    it "with nonexistent account pair raises (nil EntryType)" do
      expect {
        book.entry(:cash, :cash, "10.00".to_d, activity: activity)
      }.to raise_error(NoMethodError)
    end
  end

  describe "#apply" do
    let(:book) { described_class.new(:default, accountant: accountant) }

    it "applies an Entry to accounts" do
      entry_type = Morty::EntryType.find_by_accounts(:cash, :principal)
      entry = Morty::Entry.new(entry_type: entry_type, amount: "50.00".to_d)

      book.apply(entry)

      expect(accounts_hash[:cash]).to eq "50.00".to_d
      expect(accounts_hash[:principal]).to eq "-50.00".to_d
    end

    it "applies an Activity's entries matching the book's ledger" do
      activity = create_activity_with_entries!(amount: "75.00".to_d)

      book.apply(activity)

      expect(accounts_hash[:cash]).to eq "75.00".to_d
      expect(accounts_hash[:principal]).to eq "-75.00".to_d
    end
  end

  describe "#balances" do
    let(:book) { described_class.new(:default, accountant: accountant) }

    it "returns named balance sums" do
      accounts_hash[:cash] = "100.00".to_d
      accounts_hash[:principal] = "-50.00".to_d

      expect(book.balances[:total]).to eq "50.00".to_d
    end
  end
end
