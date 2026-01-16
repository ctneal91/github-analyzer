class GithubClient
  BASE_URL = "https://api.github.com".freeze
  EVENTS_ENDPOINT = "/events".freeze

  class RateLimitExceeded < StandardError
    attr_reader :resets_at

    def initialize(resets_at)
      @resets_at = resets_at
      super("Rate limit exceeded. Resets at #{resets_at}")
    end
  end

  class ApiError < StandardError; end

  def initialize
    @connection = Faraday.new(url: BASE_URL) do |f|
      f.request :json
      f.response :json
      f.response :raise_error
    end
  end

  def fetch_events
    check_rate_limit!

    response = @connection.get(EVENTS_ENDPOINT) do |req|
      req.headers["Accept"] = "application/vnd.github.v3+json"
      req.headers["User-Agent"] = "GitHubAnalyzer/1.0"
    end

    update_rate_limit!(response)
    log_request_success(EVENTS_ENDPOINT, response)

    response.body
  rescue Faraday::ClientError => e
    handle_client_error(e)
  rescue Faraday::Error => e
    raise ApiError, "GitHub API error: #{e.message}"
  end

  def fetch_actor(url)
    fetch_resource(url, "actor")
  end

  def fetch_repository(url)
    fetch_resource(url, "repository")
  end

  def rate_limit_state
    RateLimitState.for(full_url(EVENTS_ENDPOINT))
  end

  private

  def fetch_resource(url, resource_type)
    check_rate_limit!

    response = @connection.get(url) do |req|
      req.headers["Accept"] = "application/vnd.github.v3+json"
      req.headers["User-Agent"] = "GitHubAnalyzer/1.0"
    end

    update_rate_limit!(response)
    log_request_success(url, response)

    response.body
  rescue Faraday::ResourceNotFound
    Rails.logger.warn("[GitHubClient] #{resource_type} not found: #{url}")
    nil
  rescue Faraday::ClientError => e
    handle_client_error(e)
  rescue Faraday::Error => e
    raise ApiError, "GitHub API error fetching #{resource_type}: #{e.message}"
  end

  def check_rate_limit!
    state = rate_limit_state
    return if state.can_make_request?

    Rails.logger.warn(
      "[GitHubClient] Rate limit exhausted. Resets at #{state.resets_at}"
    )
    raise RateLimitExceeded, state.resets_at
  end

  def update_rate_limit!(response)
    remaining = response.headers["x-ratelimit-remaining"]&.to_i
    reset_time = response.headers["x-ratelimit-reset"]&.to_i

    return unless remaining && reset_time

    rate_limit_state.record_request!(remaining: remaining, resets_at: reset_time)

    if remaining < 10
      Rails.logger.warn(
        "[GitHubClient] Rate limit low: #{remaining} requests remaining"
      )
    end
  end

  def handle_client_error(error)
    if error.response&.dig(:status) == 403
      reset_time = error.response&.dig(:headers, "x-ratelimit-reset")&.to_i
      if reset_time
        resets_at = Time.at(reset_time)
        rate_limit_state.record_request!(remaining: 0, resets_at: reset_time)
        raise RateLimitExceeded, resets_at
      end
    end

    raise ApiError, "GitHub API client error: #{error.message}"
  end

  def log_request_success(endpoint, response)
    remaining = response.headers["x-ratelimit-remaining"]
    Rails.logger.info(
      "[GitHubClient] Request to #{endpoint} successful. " \
      "Rate limit remaining: #{remaining}"
    )
  end

  def full_url(endpoint)
    "#{BASE_URL}#{endpoint}"
  end
end
