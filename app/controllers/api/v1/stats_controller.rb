module Api
  module V1
    class StatsController < BaseController
      def index
        render json: {
          total_events: PushEvent.count,
          enriched_events: PushEvent.enriched.count,
          unenriched_events: PushEvent.unenriched.count,
          total_actors: Actor.count,
          total_repositories: Repository.count
        }
      end

      def rate_limit
        state = GithubClient.new.rate_limit_state

        render json: {
          remaining: state.remaining,
          resets_at: state.resets_at,
          can_make_requests: state.can_make_request?,
          time_until_reset: state.time_until_reset.to_i
        }
      end
    end
  end
end
