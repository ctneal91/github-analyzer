require "rails_helper"

RSpec.describe GithubClient do
  subject(:client) { described_class.new }

  let(:events_response) do
    [
      { "id" => "123", "type" => "PushEvent", "payload" => {} },
      { "id" => "456", "type" => "WatchEvent", "payload" => {} }
    ]
  end

  let(:rate_limit_headers) do
    {
      "x-ratelimit-remaining" => "59",
      "x-ratelimit-reset" => (Time.now + 1.hour).to_i.to_s
    }
  end

  before do
    # Clear any existing rate limit state
    RateLimitState.delete_all
  end

  describe "#fetch_events" do
    context "when API returns successfully" do
      before do
        stub_request(:get, "https://api.github.com/events")
          .to_return(
            status: 200,
            body: events_response.to_json,
            headers: rate_limit_headers.merge("content-type" => "application/json")
          )
      end

      it "returns parsed events" do
        events = client.fetch_events
        expect(events).to eq(events_response)
      end

      it "updates rate limit state" do
        client.fetch_events
        state = client.rate_limit_state
        expect(state.remaining).to eq(59)
      end

      it "logs the request" do
        expect(Rails.logger).to receive(:info).with(/Request to .* successful/)
        client.fetch_events
      end
    end

    context "when rate limit is exceeded" do
      before do
        create(:rate_limit_state,
          endpoint: "https://api.github.com/events",
          remaining: 0,
          resets_at: 30.minutes.from_now)
      end

      it "raises RateLimitExceeded without making a request" do
        expect { client.fetch_events }.to raise_error(GithubClient::RateLimitExceeded)
        expect(WebMock).not_to have_requested(:get, "https://api.github.com/events")
      end
    end

    context "when API returns 403 rate limit error" do
      let(:reset_time) { (Time.now + 1.hour).to_i }

      before do
        stub_request(:get, "https://api.github.com/events")
          .to_return(
            status: 403,
            body: { message: "API rate limit exceeded" }.to_json,
            headers: {
              "x-ratelimit-remaining" => "0",
              "x-ratelimit-reset" => reset_time.to_s,
              "content-type" => "application/json"
            }
          )
      end

      it "raises RateLimitExceeded" do
        expect { client.fetch_events }.to raise_error(GithubClient::RateLimitExceeded)
      end

      it "updates rate limit state to zero" do
        begin
          client.fetch_events
        rescue GithubClient::RateLimitExceeded
          # expected
        end

        state = client.rate_limit_state
        expect(state.remaining).to eq(0)
      end
    end

    context "when API returns other client error" do
      before do
        stub_request(:get, "https://api.github.com/events")
          .to_return(status: 400, body: "Bad request")
      end

      it "raises ApiError" do
        expect { client.fetch_events }.to raise_error(GithubClient::ApiError)
      end
    end

    context "when API returns server error" do
      before do
        stub_request(:get, "https://api.github.com/events")
          .to_return(status: 500, body: "Server error")
      end

      it "raises ApiError" do
        expect { client.fetch_events }.to raise_error(GithubClient::ApiError)
      end
    end

    context "when rate limit is low" do
      before do
        stub_request(:get, "https://api.github.com/events")
          .to_return(
            status: 200,
            body: [].to_json,
            headers: {
              "x-ratelimit-remaining" => "5",
              "x-ratelimit-reset" => (Time.now + 1.hour).to_i.to_s,
              "content-type" => "application/json"
            }
          )
      end

      it "logs a warning" do
        expect(Rails.logger).to receive(:warn).with(/Rate limit low/)
        client.fetch_events
      end
    end
  end

  describe "#fetch_actor" do
    let(:actor_url) { "https://api.github.com/users/octocat" }
    let(:actor_data) { { "id" => 1, "login" => "octocat" } }

    context "when actor exists" do
      before do
        stub_request(:get, actor_url)
          .to_return(
            status: 200,
            body: actor_data.to_json,
            headers: rate_limit_headers.merge("content-type" => "application/json")
          )
      end

      it "returns actor data" do
        result = client.fetch_actor(actor_url)
        expect(result).to eq(actor_data)
      end
    end

    context "when actor not found" do
      before do
        stub_request(:get, actor_url)
          .to_return(status: 404, body: "Not found")
      end

      it "returns nil" do
        result = client.fetch_actor(actor_url)
        expect(result).to be_nil
      end

      it "logs a warning" do
        expect(Rails.logger).to receive(:warn).with(/actor not found/)
        client.fetch_actor(actor_url)
      end
    end
  end

  describe "#fetch_repository" do
    let(:repo_url) { "https://api.github.com/repos/octocat/Hello-World" }
    let(:repo_data) { { "id" => 1, "name" => "Hello-World", "full_name" => "octocat/Hello-World" } }

    context "when repository exists" do
      before do
        stub_request(:get, repo_url)
          .to_return(
            status: 200,
            body: repo_data.to_json,
            headers: rate_limit_headers.merge("content-type" => "application/json")
          )
      end

      it "returns repository data" do
        result = client.fetch_repository(repo_url)
        expect(result).to eq(repo_data)
      end
    end

    context "when repository not found" do
      before do
        stub_request(:get, repo_url)
          .to_return(status: 404, body: "Not found")
      end

      it "returns nil" do
        result = client.fetch_repository(repo_url)
        expect(result).to be_nil
      end
    end
  end

  describe "#rate_limit_state" do
    it "returns rate limit state for events endpoint" do
      state = client.rate_limit_state
      expect(state.endpoint).to eq("https://api.github.com/events")
    end

    it "creates state if it does not exist" do
      expect { client.rate_limit_state }.to change(RateLimitState, :count).by(1)
    end
  end
end
