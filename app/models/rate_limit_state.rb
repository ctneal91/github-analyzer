class RateLimitState < ApplicationRecord
  validates :endpoint, presence: true, uniqueness: true
  validates :remaining, presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :resets_at, presence: true

  def self.for(endpoint)
    find_or_create_by!(endpoint: endpoint) do |state|
      state.remaining = 60
      state.resets_at = 1.hour.from_now
    end
  end

  def can_make_request?
    return true if reset_if_expired
    remaining > 0
  end

  def record_request!(remaining:, resets_at:)
    update!(remaining: remaining, resets_at: Time.at(resets_at))
  end

  def time_until_reset
    [ resets_at - Time.current, 0 ].max
  end

  private

  def reset_if_expired
    return false if resets_at > Time.current
    update!(remaining: 60, resets_at: 1.hour.from_now)
    true
  end
end
