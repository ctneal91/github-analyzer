namespace :github do
  desc "Ingest GitHub push events from the public events API"
  task ingest: :environment do
    puts "Starting GitHub event ingestion..."

    service = EventIngestionService.new
    results = service.ingest

    puts "\nIngestion complete!"
    puts "  Ingested: #{results[:ingested]}"
    puts "  Skipped:  #{results[:skipped]} (duplicates)"
    puts "  Errors:   #{results[:errors]}"

    # Show rate limit status
    client = GithubClient.new
    state = client.rate_limit_state
    puts "\nRate limit status:"
    puts "  Remaining: #{state.remaining}"
    puts "  Resets at: #{state.resets_at}"
  end

  desc "Show current rate limit status"
  task rate_limit: :environment do
    client = GithubClient.new
    state = client.rate_limit_state

    puts "Rate limit status for GitHub Events API:"
    puts "  Remaining: #{state.remaining}"
    puts "  Resets at: #{state.resets_at}"

    if state.can_make_request?
      puts "  Status: OK - Can make requests"
    else
      puts "  Status: BLOCKED - Wait #{state.time_until_reset.to_i} seconds"
    end
  end
end
