class PantryScan < ApplicationRecord
  MAX_PHOTOS = 5
  MAX_PHOTO_SIZE = 8.megabytes
  MAX_TOTAL_PHOTOS_SIZE = 20.megabytes
  ANALYSIS_TIMEOUT = 10.minutes
  ALLOWED_PHOTO_CONTENT_TYPES = %w[image/jpeg image/png image/webp].freeze
  ANALYSIS_ERROR_MESSAGES = {
    "service_unavailable" => "Le service d’analyse est temporairement indisponible. " \
                             "Vous pouvez relancer sans renvoyer vos photos.",
    "invalid_response" => "L’analyse n’a pas produit de résultat exploitable. Vous pouvez la relancer.",
    "queue_unavailable" => "L’analyse n’a pas pu démarrer. Réessayez dans quelques instants.",
    "technical_error" => "Un incident technique a interrompu l’analyse.",
    "timeout" => "L’analyse a pris trop de temps et peut être relancée."
  }.freeze

  belongs_to :user
  has_many_attached :photos
  has_many :pantry_items, dependent: :nullify

  include PantryScanAnalysis

  validates :status, inclusion: { in: %w[processing pending_review completed discarded failed] }
  validate :photos_must_be_attached
  validate :photos_must_use_supported_formats
  validate :photos_count_within_limit
  validate :photos_must_be_within_size_limit
  validate :photos_total_size_within_limit

  def processing?
    status == 'processing'
  end

  def failed?
    status == 'failed'
  end

  def completed?
    status == 'completed'
  end

  def pending_review?
    status == 'pending_review'
  end

  def discarded?
    status == 'discarded'
  end

  private

  def photos_must_be_attached
    return if photos.attached?

    errors.add(:photos, "doit être attaché")
  end

  def photos_must_use_supported_formats
    return unless photos.attached?

    invalid_attachments = photos.reject { |photo| photo.content_type.in?(ALLOWED_PHOTO_CONTENT_TYPES) }
    return if invalid_attachments.empty?

    errors.add(:photos, "doivent être au format JPG, PNG ou WebP")
  end

  def photos_count_within_limit
    return unless photos.attachments.size > MAX_PHOTOS

    errors.add(:photos, "doivent contenir entre 1 et #{MAX_PHOTOS} images")
  end

  def photos_must_be_within_size_limit
    return unless photos.any? { |photo| photo.byte_size > MAX_PHOTO_SIZE }

    errors.add(:photos, "doivent peser #{MAX_PHOTO_SIZE / 1.megabyte} Mo maximum chacune")
  end

  def photos_total_size_within_limit
    return unless photos.sum(&:byte_size) > MAX_TOTAL_PHOTOS_SIZE

    errors.add(:photos, "ne doivent pas dépasser #{MAX_TOTAL_PHOTOS_SIZE / 1.megabyte} Mo au total")
  end
end
