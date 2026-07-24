require "base64"

class PantryScanJob < ApplicationJob
  queue_as :default

  def perform(pantry_scan_id, analysis_token = nil)
    scan = PantryScan.find(pantry_scan_id)
    return unless scan.current_analysis?(analysis_token)

    detector = LLM::IngredientDetector.new(encoded_photos(scan))
    ingredients = detector.detect
    transitioned = scan.complete_analysis!(analysis_token, detected_items: ingredients)
    broadcast_scan_update(scan) if transitioned
  rescue LLM::IngredientDetector::DetectionError => e
    handle_failure(scan, pantry_scan_id, analysis_token, e, code: e.code)
  rescue StandardError => e
    handle_failure(scan, pantry_scan_id, analysis_token, e, code: "technical_error")
  end

  private

  def encoded_photos(scan)
    scan.photos.map do |photo|
      encoded = Base64.strict_encode64(photo.download)
      "data:#{photo.content_type};base64,#{encoded}"
    end
  end

  def handle_failure(scan, pantry_scan_id, analysis_token, error, code:)
    Rails.logger.error(
      "PantryScanJob failed for scan #{pantry_scan_id}: #{error.class} code=#{code}"
    )
    Rails.error.report(error, handled: true)
    transitioned = scan&.fail_analysis!(analysis_token, code: code)
    broadcast_scan_update(scan) if transitioned
  end

  def broadcast_scan_update(scan)
    Turbo::StreamsChannel.broadcast_replace_to(
      "pantry_scan_#{scan.id}",
      target: "scan_workspace",
      partial: "pantry_scans/workspace",
      locals: { scan: scan }
    )
  rescue StandardError => e
    Rails.logger.error "PantryScanJob broadcast failed for scan #{scan.id}: #{e.class} - #{e.message}"
  end
end
