class PantryScan < ApplicationRecord
  belongs_to :user
  has_many_attached :photos

  validates :status, inclusion: { in: %w[processing completed failed] }

  def processing?
    status == 'processing'
  end

  def completed?
    status == 'completed'
  end
end
