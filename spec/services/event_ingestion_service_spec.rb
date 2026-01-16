require "rails_helper"

RSpec.describe EventIngestionService do
  subject(:service) { described_class.new(client: client) }

  let(:client) { instance_double(GithubClient) }

  let(:push_event_data) do
    {
      "id" => "evt_123",
      "type" => "PushEvent",
      "payload" => {
        "push_id" => 12345,
        "ref" => "refs/heads/main",
        "head" => "abc123",
        "before" => "def456"
      },
      "actor" => { "id" => 1, "login" => "octocat" },
      "repo" => { "id" => 100, "name" => "octocat/hello-world" }
    }
  end

  let(:watch_event_data) do
    {
      "id" => "evt_456",
      "type" => "WatchEvent",
      "payload" => {}
    }
  end

  describe "#ingest" do
    context "when events are fetched successfully" do
      before do
        allow(client).to receive(:fetch_events)
          .and_return([ push_event_data, watch_event_data ])
      end

      it "creates push events" do
        expect { service.ingest }.to change(PushEvent, :count).by(1)
      end

      it "ignores non-push events" do
        service.ingest
        expect(PushEvent.find_by(github_event_id: "evt_456")).to be_nil
      end

      it "returns ingestion results" do
        results = service.ingest
        expect(results[:processed]).to eq(1)
        expect(results[:skipped]).to eq(0)
        expect(results[:errors]).to eq(0)
      end

      it "stores correct event data" do
        service.ingest
        event = PushEvent.find_by(github_event_id: "evt_123")

        expect(event.push_id).to eq(12345)
        expect(event.ref).to eq("refs/heads/main")
        expect(event.head).to eq("abc123")
        expect(event.before).to eq("def456")
        expect(event.raw_payload).to eq(push_event_data)
      end

      it "logs ingestion progress" do
        allow(Rails.logger).to receive(:info)
        allow(Rails.logger).to receive(:debug)
        expect(Rails.logger).to receive(:info).with(/Starting/)
        expect(Rails.logger).to receive(:info).with(/Found 1\/2 push events/)
        expect(Rails.logger).to receive(:info).with(/Ingested/)
        expect(Rails.logger).to receive(:info).with(/Done/)
        service.ingest
      end
    end

    context "when event already exists" do
      before do
        create(:push_event, github_event_id: "evt_123")
        allow(client).to receive(:fetch_events)
          .and_return([ push_event_data ])
      end

      it "skips duplicate events" do
        expect { service.ingest }.not_to change(PushEvent, :count)
      end

      it "returns skipped count" do
        results = service.ingest
        expect(results[:skipped]).to eq(1)
        expect(results[:processed]).to eq(0)
      end

      it "logs skipped events" do
        allow(Rails.logger).to receive(:debug)
        allow(Rails.logger).to receive(:info)
        expect(Rails.logger).to receive(:debug).with(/Duplicate/)
        service.ingest
      end
    end

    context "when rate limit is exceeded" do
      before do
        allow(client).to receive(:fetch_events)
          .and_raise(GithubClient::RateLimitExceeded.new(1.hour.from_now))
      end

      it "returns zero counts" do
        results = service.ingest
        expect(results).to eq({ processed: 0, skipped: 0, errors: 0 })
      end

      it "logs the rate limit" do
        allow(Rails.logger).to receive(:info)
        expect(Rails.logger).to receive(:warn).with(/Rate limited/)
        service.ingest
      end
    end

    context "when API error occurs" do
      before do
        allow(client).to receive(:fetch_events)
          .and_raise(GithubClient::ApiError.new("Connection failed"))
      end

      it "returns zero counts" do
        results = service.ingest
        expect(results).to eq({ processed: 0, skipped: 0, errors: 0 })
      end

      it "logs the error" do
        allow(Rails.logger).to receive(:info)
        expect(Rails.logger).to receive(:error).with(/API error/)
        service.ingest
      end
    end

    context "when no events are returned" do
      before do
        allow(client).to receive(:fetch_events).and_return([])
      end

      it "returns zero counts" do
        results = service.ingest
        expect(results).to eq({ processed: 0, skipped: 0, errors: 0 })
      end
    end

    context "when event has invalid data" do
      let(:invalid_event) do
        {
          "id" => "evt_invalid",
          "type" => "PushEvent",
          "payload" => {
            "push_id" => nil,
            "ref" => nil,
            "head" => nil,
            "before" => nil
          }
        }
      end

      before do
        allow(client).to receive(:fetch_events)
          .and_return([ invalid_event ])
      end

      it "counts as error" do
        results = service.ingest
        expect(results[:errors]).to eq(1)
        expect(results[:processed]).to eq(0)
      end

      it "logs the error" do
        allow(Rails.logger).to receive(:info)
        expect(Rails.logger).to receive(:error).with(/Invalid event/)
        service.ingest
      end
    end

    context "when unexpected error occurs for single event" do
      before do
        allow(client).to receive(:fetch_events)
          .and_return([ push_event_data ])
        allow(PushEvent).to receive(:exists?).and_raise(StandardError.new("Unexpected"))
      end

      it "counts as error and continues" do
        results = service.ingest
        expect(results[:errors]).to eq(1)
      end

      it "logs the error" do
        allow(Rails.logger).to receive(:info)
        expect(Rails.logger).to receive(:error).with(/Error processing/)
        service.ingest
      end
    end

    context "with multiple push events" do
      let(:push_event_2) do
        push_event_data.merge(
          "id" => "evt_789",
          "payload" => push_event_data["payload"].merge("push_id" => 67890)
        )
      end

      before do
        allow(client).to receive(:fetch_events)
          .and_return([ push_event_data, push_event_2 ])
      end

      it "ingests all push events" do
        expect { service.ingest }.to change(PushEvent, :count).by(2)
      end

      it "returns correct count" do
        results = service.ingest
        expect(results[:processed]).to eq(2)
      end
    end
  end
end
