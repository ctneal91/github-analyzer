require "rails_helper"

RSpec.describe StorablePayload do
  let(:storage_service) { instance_double(PayloadStorageService) }

  before do
    allow(PayloadStorageService).to receive(:new).and_return(storage_service)
  end

  describe "when payload storage is enabled" do
    before do
      allow(ENV).to receive(:[]).and_call_original
      allow(ENV).to receive(:[]).with("PAYLOAD_STORAGE_ENABLED").and_return("true")
    end

    describe "after create" do
      it "stores payload to S3" do
        allow(storage_service).to receive(:generate_key).and_return("push_events/1.json")
        expect(storage_service).to receive(:store).with("push_events/1.json", kind_of(Hash))

        create(:push_event)
      end

      it "updates payload_key after storing" do
        allow(storage_service).to receive(:generate_key).and_return("push_events/1.json")
        allow(storage_service).to receive(:store)

        event = create(:push_event)
        expect(event.reload.payload_key).to eq("push_events/1.json")
      end

      context "when storage fails" do
        before do
          allow(storage_service).to receive(:generate_key).and_return("push_events/1.json")
          allow(storage_service).to receive(:store)
            .and_raise(PayloadStorageService::StorageError.new("Connection failed"))
          allow(Rails.logger).to receive(:error)
        end

        it "logs error but does not raise" do
          expect(Rails.logger).to receive(:error).with(/Failed to store payload/)
          expect { create(:push_event) }.not_to raise_error
        end
      end
    end

    describe "after destroy" do
      it "deletes payload from S3" do
        allow(storage_service).to receive(:generate_key).and_return("push_events/1.json")
        allow(storage_service).to receive(:store)

        event = create(:push_event)
        event.reload

        expect(storage_service).to receive(:delete).with("push_events/1.json")
        event.destroy
      end

      context "when deletion fails" do
        before do
          allow(storage_service).to receive(:generate_key).and_return("push_events/1.json")
          allow(storage_service).to receive(:store)
          allow(storage_service).to receive(:delete)
            .and_raise(PayloadStorageService::StorageError.new("Connection failed"))
          allow(Rails.logger).to receive(:error)
        end

        it "logs error but does not raise" do
          event = create(:push_event)
          event.reload

          expect(Rails.logger).to receive(:error).with(/Failed to delete payload/)
          expect { event.destroy }.not_to raise_error
        end
      end
    end
  end

  describe "when payload storage is disabled" do
    before do
      allow(ENV).to receive(:[]).and_call_original
      allow(ENV).to receive(:[]).with("PAYLOAD_STORAGE_ENABLED").and_return(nil)
    end

    it "does not store payload to S3" do
      expect(storage_service).not_to receive(:store)
      create(:push_event)
    end

    it "does not set payload_key" do
      event = create(:push_event)
      expect(event.payload_key).to be_nil
    end
  end

  describe "#raw_payload" do
    context "when payload_key is present" do
      let(:stored_payload) { { "stored" => "data" } }

      before do
        allow(ENV).to receive(:[]).and_call_original
        allow(ENV).to receive(:[]).with("PAYLOAD_STORAGE_ENABLED").and_return("true")
        allow(storage_service).to receive(:generate_key).and_return("push_events/1.json")
        allow(storage_service).to receive(:store)
      end

      it "fetches payload from S3" do
        event = create(:push_event)
        event.reload

        allow(storage_service).to receive(:retrieve).with("push_events/1.json").and_return(stored_payload)

        # Clear instance variable to force fetch
        event.remove_instance_variable(:@raw_payload) if event.instance_variable_defined?(:@raw_payload)

        expect(event.raw_payload).to eq(stored_payload)
      end

      context "when S3 fetch fails" do
        before do
          allow(storage_service).to receive(:retrieve)
            .and_raise(PayloadStorageService::StorageError.new("Connection failed"))
          allow(Rails.logger).to receive(:error)
        end

        it "falls back to database value" do
          event = create(:push_event)
          event.reload

          # Clear instance variable to force fetch
          event.remove_instance_variable(:@raw_payload) if event.instance_variable_defined?(:@raw_payload)

          expect(event.raw_payload).to be_present
        end
      end
    end

    context "when payload_key is not present" do
      before do
        allow(ENV).to receive(:[]).and_call_original
        allow(ENV).to receive(:[]).with("PAYLOAD_STORAGE_ENABLED").and_return(nil)
      end

      it "returns database value" do
        event = create(:push_event)
        expect(event.raw_payload).to be_present
      end
    end
  end
end
