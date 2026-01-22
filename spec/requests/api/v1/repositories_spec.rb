require "rails_helper"

RSpec.describe "Api::V1::Repositories" do
  describe "GET /api/v1/repositories" do
    it "returns empty array when no repositories exist" do
      get "/api/v1/repositories"

      expect(response).to have_http_status(:ok)
      json = response.parsed_body

      expect(json["data"]).to eq([])
      expect(json["meta"]["total"]).to eq(0)
    end

    it "returns repositories with meta information" do
      create_list(:repository, 3)

      get "/api/v1/repositories"

      expect(response).to have_http_status(:ok)
      json = response.parsed_body

      expect(json["data"].length).to eq(3)
      expect(json["meta"]["total"]).to eq(3)
    end

    it "returns repositories ordered by event count descending" do
      repo_few = create(:repository)
      repo_many = create(:repository)

      create_list(:push_event, 2, :enriched, repository: repo_few)
      create_list(:push_event, 7, :enriched, repository: repo_many)

      get "/api/v1/repositories"

      json = response.parsed_body
      expect(json["data"].first["id"]).to eq(repo_many.id)
      expect(json["data"].first["event_count"]).to eq(7)
    end

    it "includes repository details" do
      repo = create(:repository, name: "my-repo", full_name: "owner/my-repo")

      get "/api/v1/repositories"

      json = response.parsed_body
      repo_data = json["data"].first

      expect(repo_data["name"]).to eq("my-repo")
      expect(repo_data["full_name"]).to eq("owner/my-repo")
      expect(repo_data).to have_key("event_count")
    end

    it "respects limit parameter" do
      create_list(:repository, 5)

      get "/api/v1/repositories", params: { limit: 2 }

      json = response.parsed_body
      expect(json["data"].length).to eq(2)
    end

    it "respects offset parameter" do
      create_list(:repository, 5)

      get "/api/v1/repositories", params: { offset: 3 }

      json = response.parsed_body
      expect(json["data"].length).to eq(2)
    end
  end
end
