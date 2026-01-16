require "rails_helper"

RSpec.describe PushEvent do
  describe "validations" do
    subject { build(:push_event) }

    it { is_expected.to validate_presence_of(:github_event_id) }
    it { is_expected.to validate_uniqueness_of(:github_event_id) }
    it { is_expected.to validate_presence_of(:push_id) }
    it { is_expected.to validate_presence_of(:ref) }
    it { is_expected.to validate_presence_of(:head) }
    it { is_expected.to validate_presence_of(:before) }
    it { is_expected.to validate_presence_of(:raw_payload) }
  end

  describe "associations" do
    it { is_expected.to belong_to(:repository).optional }
    it { is_expected.to belong_to(:actor).optional }
  end

  describe "scopes" do
    let!(:unenriched_event) { create(:push_event, enriched_at: nil) }
    let!(:enriched_event) { create(:push_event, :enriched) }

    describe ".unenriched" do
      it "returns only unenriched events" do
        expect(described_class.unenriched).to contain_exactly(unenriched_event)
      end
    end

    describe ".enriched" do
      it "returns only enriched events" do
        expect(described_class.enriched).to contain_exactly(enriched_event)
      end
    end
  end

  describe "#enriched?" do
    it "returns false when enriched_at is nil" do
      event = build(:push_event, enriched_at: nil)
      expect(event.enriched?).to be false
    end

    it "returns true when enriched_at is present" do
      event = build(:push_event, enriched_at: Time.current)
      expect(event.enriched?).to be true
    end
  end

  describe "#mark_enriched!" do
    it "sets enriched_at to current time" do
      event = create(:push_event)
      expect { event.mark_enriched! }.to change { event.enriched_at }.from(nil)
      expect(event.enriched_at).to be_within(1.second).of(Time.current)
    end
  end

  describe "factory" do
    it "creates a valid push_event" do
      event = build(:push_event)
      expect(event).to be_valid
    end

    it "creates unique github_event_ids" do
      event1 = create(:push_event)
      event2 = create(:push_event)
      expect(event1.github_event_id).not_to eq(event2.github_event_id)
    end

    it "supports enriched trait" do
      event = create(:push_event, :enriched)
      expect(event.enriched?).to be true
      expect(event.repository).to be_present
      expect(event.actor).to be_present
    end
  end
end
