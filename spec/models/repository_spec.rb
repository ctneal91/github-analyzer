require "rails_helper"

RSpec.describe Repository do
  describe "validations" do
    subject { build(:repository) }

    it { is_expected.to validate_presence_of(:github_id) }
    it { is_expected.to validate_uniqueness_of(:github_id) }
    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_presence_of(:full_name) }
  end

  describe "associations" do
    it { is_expected.to have_many(:push_events).dependent(:nullify) }
  end

  describe "factory" do
    it "creates a valid repository" do
      repository = build(:repository)
      expect(repository).to be_valid
    end

    it "creates unique github_ids" do
      repo1 = create(:repository)
      repo2 = create(:repository)
      expect(repo1.github_id).not_to eq(repo2.github_id)
    end
  end
end
