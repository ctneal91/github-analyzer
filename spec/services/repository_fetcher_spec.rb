require "rails_helper"

RSpec.describe RepositoryFetcher do
  subject(:fetcher) { described_class.new(client: client) }

  let(:client) { instance_double(GithubClient) }

  let(:event) do
    create(:push_event, raw_payload: {
      "repo" => {
        "id" => 456,
        "name" => "octocat/hello-world",
        "url" => "https://api.github.com/repos/octocat/hello-world"
      }
    })
  end

  describe "#find_or_fetch" do
    context "when repository already exists" do
      let!(:existing_repo) { create(:repository, github_id: 456) }

      it "returns existing repository without API call" do
        expect(client).not_to receive(:fetch_repository)
        result = fetcher.find_or_fetch(event)
        expect(result).to eq(existing_repo)
      end
    end

    context "when repository does not exist" do
      let(:api_response) do
        {
          "id" => 456,
          "name" => "hello-world",
          "full_name" => "octocat/hello-world"
        }
      end

      before do
        allow(client).to receive(:fetch_repository).and_return(api_response)
      end

      it "fetches from API and creates repository" do
        expect { fetcher.find_or_fetch(event) }.to change(Repository, :count).by(1)
      end

      it "returns created repository" do
        repo = fetcher.find_or_fetch(event)
        expect(repo.github_id).to eq(456)
        expect(repo.name).to eq("hello-world")
        expect(repo.full_name).to eq("octocat/hello-world")
      end
    end

    context "when API returns nil" do
      before do
        allow(client).to receive(:fetch_repository).and_return(nil)
      end

      it "creates repository from event data" do
        repo = fetcher.find_or_fetch(event)
        expect(repo.github_id).to eq(456)
        expect(repo.name).to eq("hello-world")
        expect(repo.full_name).to eq("octocat/hello-world")
      end
    end

    context "when event has no repo URL" do
      let(:event) do
        create(:push_event, raw_payload: {
          "repo" => {
            "id" => 789,
            "name" => "owner/repo-name"
          }
        })
      end

      it "creates repository from event data without API call" do
        expect(client).not_to receive(:fetch_repository)
        repo = fetcher.find_or_fetch(event)
        expect(repo.github_id).to eq(789)
        expect(repo.name).to eq("repo-name")
      end
    end

    context "when event has no repo data" do
      let(:event) { create(:push_event, raw_payload: { "type" => "PushEvent" }) }

      it "returns nil" do
        result = fetcher.find_or_fetch(event)
        expect(result).to be_nil
      end
    end

    context "when repo has no id" do
      let(:event) do
        create(:push_event, raw_payload: { "repo" => { "name" => "unknown/repo" } })
      end

      it "returns nil" do
        result = fetcher.find_or_fetch(event)
        expect(result).to be_nil
      end
    end
  end
end
