require "rails_helper"

RSpec.describe "Api::V1::Stats" do
  describe "GET /api/v1/stats" do
    it "returns stats with zero counts when no data exists" do
      get "/api/v1/stats"

      expect(response).to have_http_status(:ok)
      json = response.parsed_body

      expect(json["total_events"]).to eq(0)
      expect(json["enriched_events"]).to eq(0)
      expect(json["unenriched_events"]).to eq(0)
      expect(json["total_actors"]).to eq(0)
      expect(json["total_repositories"]).to eq(0)
    end

    it "returns correct counts when data exists" do
      create_list(:push_event, 3)
      create_list(:push_event, 2, :enriched)
      create_list(:actor, 4)
      create_list(:repository, 2)

      get "/api/v1/stats"

      expect(response).to have_http_status(:ok)
      json = response.parsed_body

      expect(json["total_events"]).to eq(5)
      expect(json["enriched_events"]).to eq(2)
      expect(json["unenriched_events"]).to eq(3)
      expect(json["total_actors"]).to be >= 4
      expect(json["total_repositories"]).to be >= 2
    end
  end

  describe "GET /api/v1/rate_limit" do
    it "returns rate limit status" do
      get "/api/v1/rate_limit"

      expect(response).to have_http_status(:ok)
      json = response.parsed_body

      expect(json).to have_key("remaining")
      expect(json).to have_key("resets_at")
      expect(json).to have_key("can_make_requests")
      expect(json).to have_key("time_until_reset")
    end

    it "returns correct rate limit when state exists" do
      create(:rate_limit_state,
        endpoint: "https://api.github.com/events",
        remaining: 42,
        resets_at: 30.minutes.from_now)

      get "/api/v1/rate_limit"

      json = response.parsed_body
      expect(json["remaining"]).to eq(42)
      expect(json["can_make_requests"]).to be true
    end
  end
end
