require "rails_helper"

RSpec.describe PayloadStorageService do
  subject(:service) { described_class.new(client: s3_client, bucket: bucket) }

  let(:s3_client) { instance_double(Aws::S3::Client) }
  let(:bucket) { "test-bucket" }
  let(:key) { "push_events/123.json" }
  let(:payload) { { "id" => 123, "data" => "test" } }

  describe "#store" do
    context "when successful" do
      before do
        allow(s3_client).to receive(:put_object)
      end

      it "stores payload to S3" do
        expect(s3_client).to receive(:put_object).with(
          bucket: bucket,
          key: key,
          body: payload.to_json,
          content_type: "application/json"
        )
        service.store(key, payload)
      end

      it "returns the key" do
        result = service.store(key, payload)
        expect(result).to eq(key)
      end
    end

    context "when S3 error occurs" do
      before do
        allow(s3_client).to receive(:put_object)
          .and_raise(Aws::S3::Errors::ServiceError.new(nil, "Connection failed"))
      end

      it "raises StorageError" do
        expect { service.store(key, payload) }
          .to raise_error(PayloadStorageService::StorageError, /Failed to store payload/)
      end
    end
  end

  describe "#retrieve" do
    context "when successful" do
      let(:response_body) { StringIO.new(payload.to_json) }
      let(:response) { instance_double(Aws::S3::Types::GetObjectOutput, body: response_body) }

      before do
        allow(s3_client).to receive(:get_object).and_return(response)
      end

      it "retrieves and parses payload from S3" do
        result = service.retrieve(key)
        expect(result).to eq(payload)
      end
    end

    context "when key does not exist" do
      before do
        allow(s3_client).to receive(:get_object)
          .and_raise(Aws::S3::Errors::NoSuchKey.new(nil, "Not found"))
      end

      it "returns nil" do
        result = service.retrieve(key)
        expect(result).to be_nil
      end
    end

    context "when S3 error occurs" do
      before do
        allow(s3_client).to receive(:get_object)
          .and_raise(Aws::S3::Errors::ServiceError.new(nil, "Connection failed"))
      end

      it "raises StorageError" do
        expect { service.retrieve(key) }
          .to raise_error(PayloadStorageService::StorageError, /Failed to retrieve payload/)
      end
    end
  end

  describe "#delete" do
    context "when successful" do
      before do
        allow(s3_client).to receive(:delete_object)
      end

      it "deletes payload from S3" do
        expect(s3_client).to receive(:delete_object).with(bucket: bucket, key: key)
        service.delete(key)
      end

      it "returns true" do
        result = service.delete(key)
        expect(result).to be true
      end
    end

    context "when S3 error occurs" do
      before do
        allow(s3_client).to receive(:delete_object)
          .and_raise(Aws::S3::Errors::ServiceError.new(nil, "Connection failed"))
      end

      it "raises StorageError" do
        expect { service.delete(key) }
          .to raise_error(PayloadStorageService::StorageError, /Failed to delete payload/)
      end
    end
  end

  describe "#exists?" do
    context "when object exists" do
      before do
        allow(s3_client).to receive(:head_object)
      end

      it "returns true" do
        result = service.exists?(key)
        expect(result).to be true
      end
    end

    context "when object does not exist" do
      before do
        allow(s3_client).to receive(:head_object)
          .and_raise(Aws::S3::Errors::NotFound.new(nil, "Not found"))
      end

      it "returns false" do
        result = service.exists?(key)
        expect(result).to be false
      end
    end

    context "when S3 error occurs" do
      before do
        allow(s3_client).to receive(:head_object)
          .and_raise(Aws::S3::Errors::ServiceError.new(nil, "Connection failed"))
      end

      it "raises StorageError" do
        expect { service.exists?(key) }
          .to raise_error(PayloadStorageService::StorageError, /Failed to check existence of payload/)
      end
    end
  end

  describe "#generate_key" do
    it "generates key for PushEvent" do
      key = service.generate_key(PushEvent, 123)
      expect(key).to eq("push_events/123.json")
    end

    it "generates key for Actor" do
      key = service.generate_key(Actor, 456)
      expect(key).to eq("actors/456.json")
    end

    it "generates key for Repository" do
      key = service.generate_key(Repository, 789)
      expect(key).to eq("repositories/789.json")
    end
  end
end
