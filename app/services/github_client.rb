class GithubClient
  BASE_URL = "https://api.github.com"
  EVENTS_PATH = "/events"
  LOW_RATE_LIMIT_THRESHOLD = 10

  class RateLimitExceeded < StandardError
    attr_reader :resets_at

    def initialize(resets_at)
      @resets_at = resets_at
      super("Rate limit exceeded. Resets at #{resets_at}")
    end
  end

  class ApiError < StandardError; end

  def initialize(logger: Rails.logger)
    @logger = logger
    @connection = build_connection
  end

  def fetch_events
    get(EVENTS_PATH)
  end

  def fetch_actor(url)
    get(url)
  rescue Faraday::ResourceNotFound
    log_not_found("actor", url)
    nil
  end

  def fetch_repository(url)
    get(url)
  rescue Faraday::ResourceNotFound
    log_not_found("repository", url)
    nil
  end

  def rate_limit_state
    RateLimitState.for(events_endpoint)
  end

  private

  def get(path)
    ensure_rate_limit_available!
    response = execute_request(path)
    process_response(response, path)
  rescue Faraday::ResourceNotFound
    raise
  rescue Faraday::ClientError => e
    handle_client_error(e)
  rescue Faraday::Error => e
    raise ApiError, "GitHub API error: #{e.message}"
  end

  def execute_request(path)
    @connection.get(path) do |req|
      req.headers["Accept"] = "application/vnd.github.v3+json"
      req.headers["User-Agent"] = "GitHubAnalyzer/1.0"
    end
  end

  def process_response(response, path)
    update_rate_limit(response)
    log_success(path, response)
    response.body
  end

  def ensure_rate_limit_available!
    state = rate_limit_state
    return if state.can_make_request?

    @logger.warn("[GithubClient] Rate limit exhausted. Resets at #{state.resets_at}")
    raise RateLimitExceeded, state.resets_at
  end

  def update_rate_limit(response)
    remaining = extract_remaining(response)
    reset_time = extract_reset_time(response)
    return unless remaining && reset_time

    rate_limit_state.record_request!(remaining: remaining, resets_at: reset_time)
    warn_if_rate_limit_low(remaining)
  end

  def extract_remaining(response)
    response.headers["x-ratelimit-remaining"]&.to_i
  end

  def extract_reset_time(response)
    response.headers["x-ratelimit-reset"]&.to_i
  end

  def warn_if_rate_limit_low(remaining)
    return unless remaining < LOW_RATE_LIMIT_THRESHOLD
    @logger.warn("[GithubClient] Rate limit low: #{remaining} requests remaining")
  end

  def handle_client_error(error)
    raise RateLimitExceeded, parse_reset_time(error) if rate_limit_error?(error)
    raise ApiError, "GitHub API client error: #{error.message}"
  end

  def rate_limit_error?(error)
    return false unless error.response&.dig(:status) == 403
    reset_time = parse_reset_time(error)
    return false unless reset_time

    rate_limit_state.record_request!(remaining: 0, resets_at: reset_time.to_i)
    true
  end

  def parse_reset_time(error)
    timestamp = error.response&.dig(:headers, "x-ratelimit-reset")&.to_i
    return nil unless timestamp&.positive?
    Time.at(timestamp)
  end

  def log_success(path, response)
    remaining = extract_remaining(response)
    @logger.info("[GithubClient] GET #{path} - OK (#{remaining} remaining)")
  end

  def log_not_found(resource_type, url)
    @logger.warn("[GithubClient] #{resource_type} not found: #{url}")
  end

  def build_connection
    Faraday.new(url: BASE_URL) do |conn|
      conn.request :json
      conn.response :json
      conn.response :raise_error
    end
  end

  def events_endpoint
    "#{BASE_URL}#{EVENTS_PATH}"
  end
end
