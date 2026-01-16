class PushEvent < ApplicationRecord
  belongs_to :repository, optional: true
  belongs_to :actor, optional: true

  validates :github_event_id, presence: true, uniqueness: true
  validates :push_id, presence: true
  validates :ref, presence: true
  validates :head, presence: true
  validates :before, presence: true
  validates :raw_payload, presence: true

  scope :unenriched, -> { where(enriched_at: nil) }
  scope :enriched, -> { where.not(enriched_at: nil) }

  def enriched?
    enriched_at.present?
  end

  def mark_enriched!
    update!(enriched_at: Time.current)
  end
end
