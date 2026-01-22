require "rails_helper"

RSpec.describe "Api::V1::Admin" do
  describe "POST /api/v1/admin/ingest" do
    let(:ingestion_service) { instance_double(EventIngestionService) }

    before do
      allow(EventIngestionService).to receive(:new).and_return(ingestion_service)
    end

    it "triggers ingestion and returns results" do
      allow(ingestion_service).to receive(:ingest).and_return(
        processed: 5,
        skipped: 2,
        errors: 0
      )

      post "/api/v1/admin/ingest"

      expect(response).to have_http_status(:ok)
      json = response.parsed_body

      expect(json["status"]).to eq("completed")
      expect(json["processed"]).to eq(5)
      expect(json["skipped"]).to eq(2)
      expect(json["errors"]).to eq(0)
    end

    it "handles rate limit exceeded" do
      allow(ingestion_service).to receive(:ingest).and_raise(
        GithubClient::RateLimitExceeded.new(1.hour.from_now)
      )

      post "/api/v1/admin/ingest"

      expect(response).to have_http_status(:too_many_requests)
      json = response.parsed_body

      expect(json["status"]).to eq("rate_limited")
      expect(json["error"]).to include("rate limit")
    end
  end

  describe "POST /api/v1/admin/enrich" do
    let(:enrichment_service) { instance_double(EventEnrichmentService) }

    before do
      allow(EventEnrichmentService).to receive(:new).and_return(enrichment_service)
    end

    it "triggers enrichment and returns results" do
      allow(enrichment_service).to receive(:enrich_all).and_return(
        processed: 10,
        skipped: 0,
        errors: 1
      )

      post "/api/v1/admin/enrich"

      expect(response).to have_http_status(:ok)
      json = response.parsed_body

      expect(json["status"]).to eq("completed")
      expect(json["processed"]).to eq(10)
      expect(json["skipped"]).to eq(0)
      expect(json["errors"]).to eq(1)
    end

    it "handles rate limit exceeded" do
      allow(enrichment_service).to receive(:enrich_all).and_raise(
        GithubClient::RateLimitExceeded.new(1.hour.from_now)
      )

      post "/api/v1/admin/enrich"

      expect(response).to have_http_status(:too_many_requests)
      json = response.parsed_body

      expect(json["status"]).to eq("rate_limited")
    end
  end

  describe "POST /api/v1/admin/sync" do
    let(:ingestion_service) { instance_double(EventIngestionService) }
    let(:enrichment_service) { instance_double(EventEnrichmentService) }

    before do
      allow(EventIngestionService).to receive(:new).and_return(ingestion_service)
      allow(EventEnrichmentService).to receive(:new).and_return(enrichment_service)
    end

    it "triggers both services and returns combined results" do
      allow(ingestion_service).to receive(:ingest).and_return(
        processed: 5,
        skipped: 2,
        errors: 0
      )
      allow(enrichment_service).to receive(:enrich_all).and_return(
        processed: 3,
        skipped: 0,
        errors: 0
      )

      post "/api/v1/admin/sync"

      expect(response).to have_http_status(:ok)
      json = response.parsed_body

      expect(json["status"]).to eq("completed")
      expect(json["ingestion"]["processed"]).to eq(5)
      expect(json["enrichment"]["processed"]).to eq(3)
    end

    it "handles rate limit during sync" do
      allow(ingestion_service).to receive(:ingest).and_raise(
        GithubClient::RateLimitExceeded.new(1.hour.from_now)
      )

      post "/api/v1/admin/sync"

      expect(response).to have_http_status(:too_many_requests)
    end
  end
end
