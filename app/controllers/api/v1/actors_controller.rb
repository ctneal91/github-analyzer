module Api
  module V1
    class ActorsController < BaseController
      def index
        actors = fetch_actors_with_event_count

        render json: {
          data: actors.map { |a| ActorPresenter.for_list(a) },
          meta: pagination_meta(Actor.count)
        }
      end

      private

      def fetch_actors_with_event_count
        Actor.left_joins(:push_events)
             .select("actors.*, COUNT(push_events.id) as event_count")
             .group("actors.id")
             .order("event_count DESC")
             .limit(pagination_limit)
             .offset(pagination_offset)
      end
    end
  end
end
