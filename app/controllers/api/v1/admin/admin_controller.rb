module Api
  module V1
    module Admin
      class AdminController < BaseController
        def ingest
          result = EventIngestionService.new.ingest
          render json: completed_response(result)
        end

        def enrich
          result = EventEnrichmentService.new.enrich_all
          render json: completed_response(result)
        end

        def sync
          ingest_result = EventIngestionService.new.ingest
          enrich_result = EventEnrichmentService.new.enrich_all

          render json: {
            status: "completed",
            ingestion: service_result(ingest_result),
            enrichment: service_result(enrich_result)
          }
        end

        private

        def completed_response(result)
          { status: "completed" }.merge(service_result(result))
        end

        def service_result(result)
          {
            processed: result[:processed],
            skipped: result[:skipped],
            errors: result[:errors]
          }
        end
      end
    end
  end
end
