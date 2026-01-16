namespace :github do
  desc "Ingest GitHub push events from the public events API"
  task ingest: :environment do
    puts "Starting GitHub event ingestion..."

    service = EventIngestionService.new
    results = service.ingest

    puts "\nIngestion complete!"
    puts "  Ingested: #{results[:processed]}"
    puts "  Skipped:  #{results[:skipped]} (duplicates)"
    puts "  Errors:   #{results[:errors]}"

    show_rate_limit_status
  end

  desc "Enrich push events with actor and repository data"
  task enrich: :environment do
    puts "Starting event enrichment..."

    service = EventEnrichmentService.new
    results = service.enrich_all

    puts "\nEnrichment complete!"
    puts "  Enriched: #{results[:processed]}"
    puts "  Skipped:  #{results[:skipped]}"
    puts "  Errors:   #{results[:errors]}"

    unenriched = PushEvent.unenriched.count
    puts "\nRemaining unenriched events: #{unenriched}"

    show_rate_limit_status
  end

  desc "Run full ingestion and enrichment pipeline"
  task sync: :environment do
    puts "=" * 50
    puts "Starting GitHub sync..."
    puts "=" * 50

    Rake::Task["github:ingest"].invoke
    puts "\n"
    Rake::Task["github:enrich"].invoke

    puts "\n" + "=" * 50
    puts "Sync complete!"
    puts "=" * 50
    show_stats
  end

  desc "Show current rate limit status"
  task rate_limit: :environment do
    show_rate_limit_status
  end

  desc "Show database statistics"
  task stats: :environment do
    show_stats
  end

  private

  def show_rate_limit_status
    client = GithubClient.new
    state = client.rate_limit_state

    puts "\nRate limit status:"
    puts "  Remaining: #{state.remaining}"
    puts "  Resets at: #{state.resets_at}"

    if state.can_make_request?
      puts "  Status: OK - Can make requests"
    else
      puts "  Status: BLOCKED - Wait #{state.time_until_reset.to_i} seconds"
    end
  end

  def show_stats
    puts "\nDatabase statistics:"
    puts "  Push events: #{PushEvent.count}"
    puts "    - Enriched: #{PushEvent.enriched.count}"
    puts "    - Unenriched: #{PushEvent.unenriched.count}"
    puts "  Actors: #{Actor.count}"
    puts "  Repositories: #{Repository.count}"
  end
end
