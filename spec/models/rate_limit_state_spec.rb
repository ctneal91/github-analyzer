require "rails_helper"

RSpec.describe RateLimitState do
  describe "validations" do
    subject { build(:rate_limit_state) }

    it { is_expected.to validate_presence_of(:endpoint) }
    it { is_expected.to validate_uniqueness_of(:endpoint) }
    it { is_expected.to validate_presence_of(:remaining) }
    it { is_expected.to validate_numericality_of(:remaining).only_integer.is_greater_than_or_equal_to(0) }
    it { is_expected.to validate_presence_of(:resets_at) }
  end

  describe ".for" do
    context "when state exists" do
      let!(:existing_state) { create(:rate_limit_state, endpoint: "https://api.github.com/events") }

      it "returns existing state" do
        state = described_class.for("https://api.github.com/events")
        expect(state).to eq(existing_state)
      end
    end

    context "when state does not exist" do
      it "creates new state with defaults" do
        state = described_class.for("https://api.github.com/new-endpoint")
        expect(state).to be_persisted
        expect(state.remaining).to eq(60)
        expect(state.resets_at).to be_within(1.second).of(1.hour.from_now)
      end
    end
  end

  describe "#can_make_request?" do
    context "when remaining > 0" do
      it "returns true" do
        state = build(:rate_limit_state, remaining: 10)
        expect(state.can_make_request?).to be true
      end
    end

    context "when remaining is 0 and not expired" do
      it "returns false" do
        state = build(:rate_limit_state, :exhausted)
        expect(state.can_make_request?).to be false
      end
    end

    context "when remaining is 0 but expired" do
      it "resets and returns true" do
        state = create(:rate_limit_state, :expired)
        expect(state.can_make_request?).to be true
        expect(state.reload.remaining).to eq(60)
      end
    end
  end

  describe "#record_request!" do
    it "updates remaining and resets_at" do
      state = create(:rate_limit_state)
      reset_time = Time.now.to_i + 3600

      state.record_request!(remaining: 42, resets_at: reset_time)

      expect(state.remaining).to eq(42)
      expect(state.resets_at).to be_within(1.second).of(Time.at(reset_time))
    end
  end

  describe "#time_until_reset" do
    it "returns seconds until reset" do
      state = build(:rate_limit_state, resets_at: 30.minutes.from_now)
      expect(state.time_until_reset).to be_within(5).of(30.minutes)
    end

    it "returns 0 if already expired" do
      state = build(:rate_limit_state, resets_at: 5.minutes.ago)
      expect(state.time_until_reset).to eq(0)
    end
  end

  describe "factory" do
    it "creates a valid rate_limit_state" do
      state = build(:rate_limit_state)
      expect(state).to be_valid
    end

    it "supports exhausted trait" do
      state = build(:rate_limit_state, :exhausted)
      expect(state.remaining).to eq(0)
      expect(state.can_make_request?).to be false
    end

    it "supports expired trait" do
      state = create(:rate_limit_state, :expired)
      expect(state.can_make_request?).to be true
    end
  end
end
