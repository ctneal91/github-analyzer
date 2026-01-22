require "rails_helper"

RSpec.describe "Api::V1::Events" do
  describe "GET /api/v1/events" do
    it "returns empty array when no events exist" do
      get "/api/v1/events"

      expect(response).to have_http_status(:ok)
      json = response.parsed_body

      expect(json["data"]).to eq([])
      expect(json["meta"]["total"]).to eq(0)
    end

    it "returns events with meta information" do
      create_list(:push_event, 3)

      get "/api/v1/events"

      expect(response).to have_http_status(:ok)
      json = response.parsed_body

      expect(json["data"].length).to eq(3)
      expect(json["meta"]["total"]).to eq(3)
      expect(json["meta"]["limit"]).to eq(50)
      expect(json["meta"]["offset"]).to eq(0)
    end

    it "returns events in descending order by created_at" do
      old_event = create(:push_event, created_at: 2.days.ago)
      new_event = create(:push_event, created_at: 1.day.ago)

      get "/api/v1/events"

      json = response.parsed_body
      expect(json["data"].first["id"]).to eq(new_event.id)
      expect(json["data"].last["id"]).to eq(old_event.id)
    end

    it "includes actor and repository when enriched" do
      actor = create(:actor)
      repository = create(:repository)
      event = create(:push_event, :enriched, actor: actor, repository: repository)

      get "/api/v1/events"

      json = response.parsed_body
      event_data = json["data"].first

      expect(event_data["actor"]["login"]).to eq(actor.login)
      expect(event_data["repository"]["full_name"]).to eq(repository.full_name)
      expect(event_data["enriched"]).to be true
    end

    it "respects limit parameter" do
      create_list(:push_event, 5)

      get "/api/v1/events", params: { limit: 2 }

      json = response.parsed_body
      expect(json["data"].length).to eq(2)
      expect(json["meta"]["limit"]).to eq(2)
    end

    it "respects offset parameter" do
      events = create_list(:push_event, 5)

      get "/api/v1/events", params: { offset: 2 }

      json = response.parsed_body
      expect(json["data"].length).to eq(3)
      expect(json["meta"]["offset"]).to eq(2)
    end

    it "caps limit at 100" do
      get "/api/v1/events", params: { limit: 500 }

      json = response.parsed_body
      expect(json["meta"]["limit"]).to eq(100)
    end
  end

  describe "GET /api/v1/events/:id" do
    it "returns event details with raw payload" do
      event = create(:push_event)

      get "/api/v1/events/#{event.id}"

      expect(response).to have_http_status(:ok)
      json = response.parsed_body

      expect(json["id"]).to eq(event.id)
      expect(json["github_event_id"]).to eq(event.github_event_id)
      expect(json["raw_payload"]).to be_present
    end

    it "includes actor and repository when enriched" do
      actor = create(:actor)
      repository = create(:repository)
      event = create(:push_event, :enriched, actor: actor, repository: repository)

      get "/api/v1/events/#{event.id}"

      json = response.parsed_body
      expect(json["actor"]["id"]).to eq(actor.id)
      expect(json["repository"]["id"]).to eq(repository.id)
    end

    it "returns 404 for non-existent event" do
      get "/api/v1/events/999999"

      expect(response).to have_http_status(:not_found)
      json = response.parsed_body
      expect(json["error"]).to eq("Not found")
    end
  end
end
