class EventIngestionService
  def initialize(client: GithubClient.new)
    @client = client
  end

  def ingest
    Rails.logger.info("[EventIngestion] Starting ingestion...")

    events = fetch_events
    return { ingested: 0, skipped: 0, errors: 0 } if events.empty?

    push_events = filter_push_events(events)
    Rails.logger.info(
      "[EventIngestion] Found #{push_events.size} push events out of #{events.size} total"
    )

    results = process_events(push_events)
    log_results(results)
    results
  end

  private

  def fetch_events
    @client.fetch_events
  rescue GithubClient::RateLimitExceeded => e
    Rails.logger.warn(
      "[EventIngestion] Rate limit exceeded. Resets at #{e.resets_at}"
    )
    []
  rescue GithubClient::ApiError => e
    Rails.logger.error("[EventIngestion] API error: #{e.message}")
    []
  end

  def filter_push_events(events)
    events.select { |e| e["type"] == "PushEvent" }
  end

  def process_events(events)
    results = { ingested: 0, skipped: 0, errors: 0 }

    events.each do |event_data|
      result = process_single_event(event_data)
      results[result] += 1
    end

    results
  end

  def process_single_event(event_data)
    github_event_id = event_data["id"]

    if PushEvent.exists?(github_event_id: github_event_id)
      Rails.logger.debug(
        "[EventIngestion] Skipping duplicate event: #{github_event_id}"
      )
      return :skipped
    end

    create_push_event(event_data)
    Rails.logger.info(
      "[EventIngestion] Ingested event: #{github_event_id}"
    )
    :ingested
  rescue ActiveRecord::RecordInvalid => e
    Rails.logger.error(
      "[EventIngestion] Failed to save event #{github_event_id}: #{e.message}"
    )
    :errors
  rescue StandardError => e
    Rails.logger.error(
      "[EventIngestion] Unexpected error for event #{github_event_id}: #{e.message}"
    )
    :errors
  end

  def create_push_event(event_data)
    payload = event_data["payload"] || {}

    PushEvent.create!(
      github_event_id: event_data["id"],
      push_id: payload["push_id"],
      ref: payload["ref"],
      head: payload["head"],
      before: payload["before"],
      raw_payload: event_data
    )
  end

  def log_results(results)
    Rails.logger.info(
      "[EventIngestion] Completed. " \
      "Ingested: #{results[:ingested]}, " \
      "Skipped: #{results[:skipped]}, " \
      "Errors: #{results[:errors]}"
    )
  end
end
