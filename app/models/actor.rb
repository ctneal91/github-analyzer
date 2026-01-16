class Actor < ApplicationRecord
  has_many :push_events, dependent: :nullify

  validates :github_id, presence: true, uniqueness: true
  validates :login, presence: true
end
