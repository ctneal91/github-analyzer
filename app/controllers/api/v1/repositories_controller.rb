module Api
  module V1
    class RepositoriesController < BaseController
      def index
        repositories = fetch_repositories_with_event_count

        render json: {
          data: repositories.map { |r| RepositoryPresenter.for_list(r) },
          meta: pagination_meta(Repository.count)
        }
      end

      private

      def fetch_repositories_with_event_count
        Repository.left_joins(:push_events)
                  .select("repositories.*, COUNT(push_events.id) as event_count")
                  .group("repositories.id")
                  .order("event_count DESC")
                  .limit(pagination_limit)
                  .offset(pagination_offset)
      end
    end
  end
end
