require "rails_helper"

RSpec.describe EventEnrichmentService do
  subject(:service) { described_class.new(client: client) }

  let(:client) { instance_double(GithubClient) }

  describe "#enrich_all" do
    context "when there are unenriched events" do
      let!(:event) do
        create(:push_event, raw_payload: {
          "actor" => { "id" => 1, "login" => "user1", "url" => "https://api.github.com/users/user1" },
          "repo" => { "id" => 100, "name" => "owner/repo", "url" => "https://api.github.com/repos/owner/repo" }
        })
      end

      let(:actor_data) { { "id" => 1, "login" => "user1", "avatar_url" => "https://example.com/avatar" } }
      let(:repo_data) { { "id" => 100, "name" => "repo", "full_name" => "owner/repo" } }

      before do
        allow(client).to receive(:fetch_actor).and_return(actor_data)
        allow(client).to receive(:fetch_repository).and_return(repo_data)
      end

      it "enriches unenriched events" do
        service.enrich_all
        event.reload
        expect(event.enriched?).to be true
      end

      it "creates actor" do
        expect { service.enrich_all }.to change(Actor, :count).by(1)
      end

      it "creates repository" do
        expect { service.enrich_all }.to change(Repository, :count).by(1)
      end

      it "returns result hash" do
        result = service.enrich_all
        expect(result[:processed]).to eq(1)
        expect(result[:skipped]).to eq(0)
        expect(result[:errors]).to eq(0)
      end

      it "logs progress" do
        allow(Rails.logger).to receive(:info)
        expect(Rails.logger).to receive(:info).with(/Starting/)
        expect(Rails.logger).to receive(:info).with(/Found 1/)
        expect(Rails.logger).to receive(:info).with(/Enriched/)
        expect(Rails.logger).to receive(:info).with(/Done/)
        service.enrich_all
      end
    end

    context "when there are no unenriched events" do
      before do
        create(:push_event, :enriched)
      end

      it "returns zero counts" do
        result = service.enrich_all
        expect(result).to eq({ processed: 0, skipped: 0, errors: 0 })
      end
    end

    context "when rate limit is exceeded during processing" do
      let!(:event) do
        create(:push_event, raw_payload: {
          "actor" => { "id" => 999, "login" => "testuser", "url" => "https://api.github.com/users/testuser" },
          "repo" => { "id" => 999, "name" => "owner/repo", "url" => "https://api.github.com/repos/owner/repo" }
        })
      end

      before do
        allow(client).to receive(:fetch_actor)
          .and_raise(GithubClient::RateLimitExceeded.new(1.hour.from_now))
      end

      it "returns partial results" do
        allow(Rails.logger).to receive(:info)
        allow(Rails.logger).to receive(:warn)
        result = service.enrich_all
        expect(result[:errors]).to eq(0)
      end

      it "logs the rate limit" do
        allow(Rails.logger).to receive(:info)
        expect(Rails.logger).to receive(:warn).with(/Rate limited/)
        service.enrich_all
      end
    end

    context "when API error occurs" do
      let!(:event) do
        create(:push_event, raw_payload: {
          "actor" => { "id" => 888, "login" => "testuser", "url" => "https://api.github.com/users/testuser" },
          "repo" => { "id" => 888, "name" => "owner/repo", "url" => "https://api.github.com/repos/owner/repo" }
        })
      end

      before do
        allow(client).to receive(:fetch_actor)
          .and_raise(GithubClient::ApiError.new("Connection failed"))
        allow(client).to receive(:fetch_repository).and_return(nil)
      end

      it "counts as error" do
        result = service.enrich_all
        expect(result[:errors]).to eq(1)
      end

      it "logs the error" do
        allow(Rails.logger).to receive(:info)
        expect(Rails.logger).to receive(:error).with(/API error/)
        service.enrich_all
      end
    end

    context "when unexpected error occurs" do
      let!(:event) do
        create(:push_event, raw_payload: {
          "actor" => { "id" => 777, "login" => "testuser", "url" => "https://api.github.com/users/testuser" },
          "repo" => { "id" => 777, "name" => "owner/repo", "url" => "https://api.github.com/repos/owner/repo" }
        })
      end

      before do
        allow(client).to receive(:fetch_actor)
          .and_raise(StandardError.new("Unexpected"))
        allow(client).to receive(:fetch_repository).and_return(nil)
      end

      it "counts as error" do
        result = service.enrich_all
        expect(result[:errors]).to eq(1)
      end

      it "logs the error" do
        allow(Rails.logger).to receive(:info)
        expect(Rails.logger).to receive(:error).with(/Error for/)
        service.enrich_all
      end
    end

    context "with existing actor and repository" do
      let!(:actor) { create(:actor, github_id: 1) }
      let!(:repository) { create(:repository, github_id: 100) }
      let!(:event) do
        create(:push_event, raw_payload: {
          "actor" => { "id" => 1, "login" => "user1" },
          "repo" => { "id" => 100, "name" => "owner/repo" }
        })
      end

      it "reuses existing records" do
        expect(client).not_to receive(:fetch_actor)
        expect(client).not_to receive(:fetch_repository)

        expect { service.enrich_all }.not_to change(Actor, :count)
        expect { service.enrich_all }.not_to change(Repository, :count)
      end

      it "links existing records to event" do
        service.enrich_all
        event.reload
        expect(event.actor).to eq(actor)
        expect(event.repository).to eq(repository)
      end
    end
  end
end
