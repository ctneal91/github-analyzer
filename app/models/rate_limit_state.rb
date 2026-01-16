class RateLimitState < ApplicationRecord
  DEFAULT_LIMIT = 60
  RESET_INTERVAL = 1.hour

  validates :endpoint, presence: true, uniqueness: true
  validates :remaining, presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :resets_at, presence: true

  def self.for(endpoint)
    find_or_create_by!(endpoint: endpoint) do |state|
      state.remaining = DEFAULT_LIMIT
      state.resets_at = RESET_INTERVAL.from_now
    end
  end

  def can_make_request?
    reset_if_expired || requests_remaining?
  end

  def record_request!(remaining:, resets_at:)
    update!(remaining: remaining, resets_at: Time.at(resets_at))
  end

  def time_until_reset
    [ resets_at - Time.current, 0 ].max
  end

  private

  def requests_remaining?
    remaining > 0
  end

  def reset_if_expired
    return false unless expired?
    reset!
    true
  end

  def expired?
    resets_at <= Time.current
  end

  def reset!
    update!(remaining: DEFAULT_LIMIT, resets_at: RESET_INTERVAL.from_now)
  end
end
