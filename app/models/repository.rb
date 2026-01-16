class Repository < ApplicationRecord
  include StorablePayload

  has_many :push_events, dependent: :nullify

  validates :github_id, presence: true, uniqueness: true
  validates :name, presence: true
  validates :full_name, presence: true
end
