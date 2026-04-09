require "spec_helper"

RSpec.describe Morty::Source do
  describe "construction" do
    it "succeeds with an object that has #id" do
      source = described_class.new(TestHelpers::SourceStub.new(42))
      expect(source.object.id).to eq 42
    end

    it "raises Morty::Error if object lacks #id" do
      expect { described_class.new(Object.new) }.to raise_error(Morty::Error, /id method/)
    end
  end

  describe "delegation" do
    it "delegates unknown methods to the wrapped object" do
      obj = Struct.new(:id, :name).new(1, "test")
      source = described_class.new(obj)
      expect(source.name).to eq "test"
    end
  end

  describe "#activities" do
    it "returns an AR relation scoped to source_id" do
      source = described_class.new(TestHelpers::SourceStub.new(99999))
      relation = source.activities
      expect(relation).to be_a(ActiveRecord::Relation)
      expect(relation.to_a).to eq []
    end
  end
end
