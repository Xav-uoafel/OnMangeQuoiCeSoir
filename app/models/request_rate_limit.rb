class RequestRateLimit < ApplicationRecord
  validates :key, :window_started_at, :expires_at, presence: true
  validates :count, numericality: { only_integer: true, greater_than_or_equal_to: 0 }

  scope :expired, -> { where(expires_at: ...Time.current) }
end
