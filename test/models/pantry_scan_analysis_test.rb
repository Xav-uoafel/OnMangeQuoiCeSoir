require "base64"
require "test_helper"

class PantryScanAnalysisTest < ActiveSupport::TestCase
  PNG_BASE64 = "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVQIHWP4////fwAJ+wP9KobjigAAAABJRU5ErkJggg==".freeze

  setup do
    @scan = users(:one).pantry_scans.create!(
      label: "Frigo",
      photos: [{
        io: StringIO.new(Base64.decode64(PNG_BASE64)),
        filename: "frigo.png",
        content_type: "image/png"
      }]
    )
  end

  test "suit les tentatives et neutralise les anciens jetons" do
    first_token = @scan.start_analysis!
    second_token = @scan.start_analysis!

    assert_equal 2, @scan.analysis_attempts
    assert @scan.current_analysis?(second_token)
    assert_not @scan.current_analysis?(first_token)
    assert_not @scan.complete_analysis!(first_token, detected_items: [])

    detected_items = [{ name: "Tomate", category: "legume", quantity_text: "3" }]
    assert @scan.complete_analysis!(second_token, detected_items: detected_items)
    assert @scan.pending_review?
    assert_nil @scan.analysis_token
    assert_equal 1, @scan.items_detected
    assert_not_nil @scan.analysis_completed_at
  end

  test "detecte une analyse bloquee" do
    @scan.start_analysis!
    @scan.update!(analysis_started_at: 11.minutes.ago)

    assert @scan.analysis_stale?
    assert @scan.analysis_retryable?
    assert_includes @scan.analysis_error_message, "pris trop de temps"
  end

  test "expose un message utilisateur sans detail technique" do
    token = @scan.start_analysis!
    @scan.fail_analysis!(token, code: "queue_unavailable")

    assert @scan.failed?
    assert @scan.analysis_retryable?
    assert_includes @scan.analysis_error_message, "n’a pas pu démarrer"
  end
end
