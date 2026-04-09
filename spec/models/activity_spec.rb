require "spec_helper"

RSpec.describe Morty::Activity do
  describe "#==" do
    let(:attrs) { { activity_type: :issue, source_id: 1, accounting_date: Date.current, activity_amount: "100.00".to_d } }

    it "equals when both persisted with same id" do
      a = build_activity
      a.save!
      b = Morty::Activity.find(a.id)
      expect(a).to eq b
    end

    it "not equal when both persisted with different ids" do
      a = create_activity_with_entries!
      b = create_activity_with_entries!
      expect(a).not_to eq b
    end

    it "equals when one id is nil if business key matches" do
      saved = create_activity_with_entries!
      unsaved = build_activity(type: saved.type, source_id: saved.source_id, effective_date: saved.effective_date, amount: saved.amount)
      expect(unsaved).to eq saved
    end

    it "equals when both ids are nil and fields match" do
      a = build_activity
      b = build_activity
      expect(a).to eq b
    end

    it "not equal when types differ" do
      a = build_activity(type: :issue)
      b = build_activity(type: :payment)
      expect(a).not_to eq b
    end

    it "not equal when amounts differ" do
      a = build_activity(amount: "100.00".to_d)
      b = build_activity(amount: "200.00".to_d)
      expect(a).not_to eq b
    end

    it "not equal when effective_dates differ" do
      a = build_activity(effective_date: Date.current)
      b = build_activity(effective_date: Date.current - 1)
      expect(a).not_to eq b
    end

    it "not equal with a non-Activity" do
      expect(build_activity).not_to eq "not an activity"
    end

    it "still equal when accounting_dates differ (not compared)" do
      a = build_activity(accounting_date: Date.current, effective_date: Date.current)
      b = build_activity(accounting_date: Date.current - 1, effective_date: Date.current)
      expect(a).to eq b
    end
  end

  describe "after_initialize" do
    it "defaults effective_date from accounting_date" do
      activity = described_class.new(accounting_date: Date.new(2026, 3, 15))
      expect(activity.effective_date).to eq Date.new(2026, 3, 15)
    end
  end

  describe "#retroactive?" do
    it "true when effective_date < accounting_date" do
      activity = build_activity(accounting_date: Date.current, effective_date: Date.current - 1)
      expect(activity).to be_retroactive
    end

    it "false when effective_date == accounting_date" do
      activity = build_activity
      expect(activity).not_to be_retroactive
    end
  end

  describe "#to_event" do
    it "returns a hash with amount, date, and type" do
      activity = build_activity(type: :payment, amount: "50.00".to_d)
      event = activity.to_event
      expect(event[:amount]).to eq "50.00".to_d
      expect(event[:date]).to eq activity.effective_date
      expect(event[:type]).to eq :payment
    end
  end

  describe "#cancel" do
    it "builds a cancelled_by activity with inverse entries" do
      activity = create_activity_with_entries!(type: :issue, amount: "500.00".to_d)
      cancel = activity.cancel(Date.current, :cancel)

      expect(cancel.type).to eq :cancel
      expect(cancel.source_id).to eq activity.source_id
      expect(cancel.effective_date).to eq activity.effective_date
      expect(cancel.accounting_date).to eq Date.current
      expect(cancel.cancels).to eq activity
      expect(cancel.entries.size).to eq activity.entries.size

      original_type = activity.entries.first.entry_type
      cancel_type = cancel.entries.first.entry_type
      expect(cancel_type.dr).to eq original_type.cr
      expect(cancel_type.cr).to eq original_type.dr
    end
  end

  describe "#reverse" do
    it "builds a reversal with inverse entries but no amount or effective_date" do
      activity = create_activity_with_entries!(type: :issue, amount: "500.00".to_d)
      reversal = activity.reverse(Date.current, :reversal)

      expect(reversal.type).to eq :reversal
      expect(reversal.source_id).to eq activity.source_id
      expect(reversal.accounting_date).to eq Date.current
      expect(reversal.amount).to be_nil
      expect(reversal.entries.size).to eq activity.entries.size
    end
  end

  describe "predicate methods" do
    it "#cancelled? is false by default" do
      expect(build_activity).not_to be_cancelled
    end

    it "#cancels? is false by default" do
      expect(build_activity).not_to be_cancels
    end

    it "#cancelling? is true for both sides of a cancellation" do
      activity = create_activity_with_entries!
      cancel = activity.cancel(Date.current, :cancel)

      expect(cancel).to be_cancelling
      expect(activity).to be_cancelling
    end
  end
end
