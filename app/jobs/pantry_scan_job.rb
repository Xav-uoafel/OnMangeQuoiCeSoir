class PantryScanJob < ApplicationJob
  queue_as :default

  def perform(pantry_scan_id)
    scan = PantryScan.find(pantry_scan_id)
    return unless scan.processing?

    image_urls = scan.photos.map do |photo|
      Rails.application.routes.url_helpers.rails_blob_url(photo, host: ENV.fetch('APP_HOST', 'http://localhost:3000'))
    end

    detector = LLM::IngredientDetector.new(image_urls)
    ingredients = detector.detect

    ActiveRecord::Base.transaction do
      ingredients.each do |ingredient|
        scan.user.pantry_items.create!(
          name: ingredient[:name],
          category: ingredient[:category],
          quantity_text: ingredient[:quantity_text],
          detected_on: Date.current,
          source: 'photo_scan'
        )
      end

      scan.update!(status: 'completed', items_detected: ingredients.size)
    end

    broadcast_scan_update(scan)
  rescue StandardError => e
    Rails.logger.error "PantryScanJob failed for scan #{pantry_scan_id}: #{e.message}"
    scan&.update!(status: 'failed')
    broadcast_scan_update(scan) if scan
  end

  private

  def broadcast_scan_update(scan)
    Turbo::StreamsChannel.broadcast_replace_to(
      "pantry_scan_#{scan.id}",
      target: "scan_status",
      partial: "pantry_scans/status",
      locals: { scan: scan }
    )
  end
end
