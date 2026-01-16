class EventIngestionService
  PUSH_EVENT_TYPE = "PushEvent"

  def initialize(client: GithubClient.new, logger: Rails.logger)
    @client = client
    @logger = logger
  end

  def ingest
    @logger.info("[EventIngestion] Starting...")
    result = IngestionResult.new

    events = fetch_events
    return empty_result if events.empty?

    push_events = select_push_events(events)
    log_event_count(events.size, push_events.size)

    process_events(push_events, result)
    log_completion(result)

    result.to_h
  end

  private

  def fetch_events
    @client.fetch_events
  rescue GithubClient::RateLimitExceeded => e
    @logger.warn("[EventIngestion] Rate limited until #{e.resets_at}")
    []
  rescue GithubClient::ApiError => e
    @logger.error("[EventIngestion] API error: #{e.message}")
    []
  end

  def select_push_events(events)
    events.select { |event| event["type"] == PUSH_EVENT_TYPE }
  end

  def process_events(events, result)
    events.each { |event| process_event(event, result) }
  end

  def process_event(event_data, result)
    event_id = event_data["id"]

    if already_ingested?(event_id)
      @logger.debug("[EventIngestion] Duplicate: #{event_id}")
      result.record_skipped
      return
    end

    create_push_event(event_data)
    @logger.info("[EventIngestion] Ingested: #{event_id}")
    result.record_processed
  rescue ActiveRecord::RecordInvalid => e
    @logger.error("[EventIngestion] Invalid event #{event_id}: #{e.message}")
    result.record_error
  rescue StandardError => e
    @logger.error("[EventIngestion] Error processing #{event_id}: #{e.message}")
    result.record_error
  end

  def already_ingested?(event_id)
    PushEvent.exists?(github_event_id: event_id)
  end

  def create_push_event(event_data)
    payload = event_data.fetch("payload", {})

    PushEvent.create!(
      github_event_id: event_data["id"],
      push_id: payload["push_id"],
      ref: payload["ref"],
      head: payload["head"],
      before: payload["before"],
      raw_payload: event_data
    )
  end

  def log_event_count(total, push_count)
    @logger.info("[EventIngestion] Found #{push_count}/#{total} push events")
  end

  def log_completion(result)
    @logger.info(
      "[EventIngestion] Done: #{result.processed} ingested, " \
      "#{result.skipped} skipped, #{result.errors} errors"
    )
  end

  def empty_result
    { processed: 0, skipped: 0, errors: 0 }
  end
end
