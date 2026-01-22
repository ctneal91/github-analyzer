module Api
  module V1
    class BaseController < ApplicationController
      rescue_from ActiveRecord::RecordNotFound, with: :not_found
      rescue_from GithubClient::RateLimitExceeded, with: :rate_limit_exceeded

      private

      def not_found
        render json: { error: "Not found" }, status: :not_found
      end

      def rate_limit_exceeded(exception)
        render json: {
          status: "rate_limited",
          error: "GitHub API rate limit exceeded",
          resets_at: exception.resets_at
        }, status: :too_many_requests
      end

      def pagination_limit(default: 50, max: 100)
        [ params.fetch(:limit, default).to_i, max ].min
      end

      def pagination_offset
        params.fetch(:offset, 0).to_i
      end

      def pagination_meta(total)
        {
          total: total,
          limit: pagination_limit,
          offset: pagination_offset
        }
      end
    end
  end
end
