require "rails_helper"

RSpec.describe IngestionResult do
  subject(:result) { described_class.new }

  describe "#initialize" do
    it "starts with zero counts" do
      expect(result.processed).to eq(0)
      expect(result.skipped).to eq(0)
      expect(result.errors).to eq(0)
    end
  end

  describe "#record_processed" do
    it "increments processed count" do
      expect { result.record_processed }.to change { result.processed }.by(1)
    end
  end

  describe "#record_skipped" do
    it "increments skipped count" do
      expect { result.record_skipped }.to change { result.skipped }.by(1)
    end
  end

  describe "#record_error" do
    it "increments errors count" do
      expect { result.record_error }.to change { result.errors }.by(1)
    end
  end

  describe "#to_h" do
    it "returns hash with all counts" do
      result.record_processed
      result.record_skipped
      result.record_error

      expect(result.to_h).to eq({
        processed: 1,
        skipped: 1,
        errors: 1
      })
    end
  end

  describe "#empty?" do
    it "returns true when no records processed" do
      expect(result.empty?).to be true
    end

    it "returns false when any records processed" do
      result.record_processed
      expect(result.empty?).to be false
    end
  end

  describe "#total" do
    it "returns sum of all counts" do
      result.record_processed
      result.record_processed
      result.record_skipped
      result.record_error

      expect(result.total).to eq(4)
    end
  end
end
