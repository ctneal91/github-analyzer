module Api
  module V1
    class EventsController < BaseController
      def index
        events = fetch_events

        render json: {
          data: events.map { |e| EventPresenter.summary(e) },
          meta: pagination_meta(PushEvent.count)
        }
      end

      def show
        event = PushEvent.includes(:actor, :repository).find(params[:id])

        render json: EventPresenter.detail(event)
      end

      private

      def fetch_events
        PushEvent.includes(:actor, :repository)
                 .order(created_at: :desc)
                 .limit(pagination_limit)
                 .offset(pagination_offset)
      end
    end
  end
end
