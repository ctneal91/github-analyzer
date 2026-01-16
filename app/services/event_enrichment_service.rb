class EventEnrichmentService
  BATCH_SIZE = 20

  def initialize(client: GithubClient.new, logger: Rails.logger)
    @client = client
    @logger = logger
    @actor_fetcher = ActorFetcher.new(client: client)
    @repository_fetcher = RepositoryFetcher.new(client: client)
  end

  def enrich_all
    @logger.info("[EventEnrichment] Starting...")
    result = IngestionResult.new

    events = find_unenriched_events
    return empty_result if events.empty?

    @logger.info("[EventEnrichment] Found #{events.size} unenriched events")
    process_events(events, result)
    log_completion(result)

    result.to_h
  rescue GithubClient::RateLimitExceeded => e
    @logger.warn("[EventEnrichment] Rate limited until #{e.resets_at}")
    result.to_h
  end

  private

  def find_unenriched_events
    PushEvent.unenriched.limit(BATCH_SIZE)
  end

  def process_events(events, result)
    events.each { |event| process_event(event, result) }
  end

  def process_event(event, result)
    enrich_event(event)
    @logger.info("[EventEnrichment] Enriched: #{event.github_event_id}")
    result.record_processed
  rescue GithubClient::RateLimitExceeded
    raise
  rescue GithubClient::ApiError => e
    @logger.error("[EventEnrichment] API error for #{event.github_event_id}: #{e.message}")
    result.record_error
  rescue StandardError => e
    @logger.error("[EventEnrichment] Error for #{event.github_event_id}: #{e.message}")
    result.record_error
  end

  def enrich_event(event)
    actor = @actor_fetcher.find_or_fetch(event)
    repository = @repository_fetcher.find_or_fetch(event)

    event.update!(
      actor: actor,
      repository: repository,
      enriched_at: Time.current
    )
  end

  def log_completion(result)
    @logger.info(
      "[EventEnrichment] Done: #{result.processed} enriched, " \
      "#{result.skipped} skipped, #{result.errors} errors"
    )
  end

  def empty_result
    { processed: 0, skipped: 0, errors: 0 }
  end
end
