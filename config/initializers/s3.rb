require "aws-sdk-s3"

module S3Config
  DEFAULT_ACCESS_KEY = "minioadmin"
  DEFAULT_SECRET_KEY = "minioadmin"
  DEFAULT_REGION = "us-east-1"

  class << self
    def client
      @client ||= build_client
    end

    def bucket
      @bucket ||= ENV.fetch("S3_BUCKET") { "github-analyzer-#{Rails.env}" }
    end

    private

    def build_client
      custom_endpoint? ? build_custom_endpoint_client : build_aws_client
    end

    def custom_endpoint?
      ENV["S3_ENDPOINT"].present?
    end

    def build_custom_endpoint_client
      Aws::S3::Client.new(
        endpoint: ENV["S3_ENDPOINT"],
        access_key_id: access_key_id,
        secret_access_key: secret_access_key,
        region: region,
        force_path_style: true
      )
    end

    def build_aws_client
      Aws::S3::Client.new(region: region)
    end

    def access_key_id
      ENV.fetch("AWS_ACCESS_KEY_ID", DEFAULT_ACCESS_KEY)
    end

    def secret_access_key
      ENV.fetch("AWS_SECRET_ACCESS_KEY", DEFAULT_SECRET_KEY)
    end

    def region
      ENV.fetch("AWS_REGION", DEFAULT_REGION)
    end
  end
end

S3_CLIENT = S3Config.client
S3_BUCKET = S3Config.bucket
