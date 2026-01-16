require "rails_helper"

RSpec.describe Actor do
  describe "validations" do
    subject { build(:actor) }

    it { is_expected.to validate_presence_of(:github_id) }
    it { is_expected.to validate_uniqueness_of(:github_id) }
    it { is_expected.to validate_presence_of(:login) }
  end

  describe "associations" do
    it { is_expected.to have_many(:push_events).dependent(:nullify) }
  end

  describe "factory" do
    it "creates a valid actor" do
      actor = build(:actor)
      expect(actor).to be_valid
    end

    it "creates unique github_ids" do
      actor1 = create(:actor)
      actor2 = create(:actor)
      expect(actor1.github_id).not_to eq(actor2.github_id)
    end
  end
end
