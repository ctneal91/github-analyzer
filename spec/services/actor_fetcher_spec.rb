require "rails_helper"

RSpec.describe ActorFetcher do
  subject(:fetcher) { described_class.new(client: client) }

  let(:client) { instance_double(GithubClient) }

  let(:event) do
    create(:push_event, raw_payload: {
      "actor" => {
        "id" => 123,
        "login" => "octocat",
        "avatar_url" => "https://avatars.githubusercontent.com/u/123",
        "url" => "https://api.github.com/users/octocat"
      }
    })
  end

  describe "#find_or_fetch" do
    context "when actor already exists" do
      let!(:existing_actor) { create(:actor, github_id: 123) }

      it "returns existing actor without API call" do
        expect(client).not_to receive(:fetch_actor)
        result = fetcher.find_or_fetch(event)
        expect(result).to eq(existing_actor)
      end
    end

    context "when actor does not exist" do
      let(:api_response) do
        {
          "id" => 123,
          "login" => "octocat",
          "avatar_url" => "https://avatars.githubusercontent.com/u/123"
        }
      end

      before do
        allow(client).to receive(:fetch_actor).and_return(api_response)
      end

      it "fetches from API and creates actor" do
        expect { fetcher.find_or_fetch(event) }.to change(Actor, :count).by(1)
      end

      it "returns created actor" do
        actor = fetcher.find_or_fetch(event)
        expect(actor.github_id).to eq(123)
        expect(actor.login).to eq("octocat")
      end
    end

    context "when API returns nil" do
      before do
        allow(client).to receive(:fetch_actor).and_return(nil)
      end

      it "creates actor from event data" do
        actor = fetcher.find_or_fetch(event)
        expect(actor.github_id).to eq(123)
        expect(actor.login).to eq("octocat")
      end
    end

    context "when event has no actor URL" do
      let(:event) do
        create(:push_event, raw_payload: {
          "actor" => {
            "id" => 456,
            "login" => "user456"
          }
        })
      end

      it "creates actor from event data without API call" do
        expect(client).not_to receive(:fetch_actor)
        actor = fetcher.find_or_fetch(event)
        expect(actor.github_id).to eq(456)
      end
    end

    context "when event has no actor data" do
      let(:event) { create(:push_event, raw_payload: { "type" => "PushEvent" }) }

      it "returns nil" do
        result = fetcher.find_or_fetch(event)
        expect(result).to be_nil
      end
    end

    context "when actor has no id" do
      let(:event) do
        create(:push_event, raw_payload: { "actor" => { "login" => "unknown" } })
      end

      it "returns nil" do
        result = fetcher.find_or_fetch(event)
        expect(result).to be_nil
      end
    end
  end
end
