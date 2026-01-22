require "rails_helper"

RSpec.describe "Api::V1::Actors" do
  describe "GET /api/v1/actors" do
    it "returns empty array when no actors exist" do
      get "/api/v1/actors"

      expect(response).to have_http_status(:ok)
      json = response.parsed_body

      expect(json["data"]).to eq([])
      expect(json["meta"]["total"]).to eq(0)
    end

    it "returns actors with meta information" do
      create_list(:actor, 3)

      get "/api/v1/actors"

      expect(response).to have_http_status(:ok)
      json = response.parsed_body

      expect(json["data"].length).to eq(3)
      expect(json["meta"]["total"]).to eq(3)
    end

    it "returns actors ordered by event count descending" do
      actor_few = create(:actor)
      actor_many = create(:actor)

      create_list(:push_event, 1, :enriched, actor: actor_few)
      create_list(:push_event, 5, :enriched, actor: actor_many)

      get "/api/v1/actors"

      json = response.parsed_body
      expect(json["data"].first["id"]).to eq(actor_many.id)
      expect(json["data"].first["event_count"]).to eq(5)
    end

    it "includes actor details" do
      actor = create(:actor, login: "testuser", avatar_url: "https://example.com/avatar.png")

      get "/api/v1/actors"

      json = response.parsed_body
      actor_data = json["data"].first

      expect(actor_data["login"]).to eq("testuser")
      expect(actor_data["avatar_url"]).to eq("https://example.com/avatar.png")
      expect(actor_data).to have_key("event_count")
    end

    it "respects limit parameter" do
      create_list(:actor, 5)

      get "/api/v1/actors", params: { limit: 2 }

      json = response.parsed_body
      expect(json["data"].length).to eq(2)
    end

    it "respects offset parameter" do
      create_list(:actor, 5)

      get "/api/v1/actors", params: { offset: 3 }

      json = response.parsed_body
      expect(json["data"].length).to eq(2)
    end
  end
end
