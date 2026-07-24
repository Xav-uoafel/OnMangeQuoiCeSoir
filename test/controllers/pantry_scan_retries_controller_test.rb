require "base64"
require "test_helper"

class PantryScanRetriesControllerTest < ActionDispatch::IntegrationTest
  include ActiveJob::TestHelper

  PNG_BASE64 = "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVQIHWP4////fwAJ+wP9KobjigAAAABJRU5ErkJggg==".freeze

  setup do
    @user = users(:one)
    sign_in @user
  end

  test "relance une analyse echouee avec les photos existantes" do
    scan = @user.pantry_scans.create!(label: "A relancer", photos: [uploaded_image])
    first_token = scan.start_analysis!
    scan.fail_analysis!(first_token, code: "service_unavailable")

    assert_enqueued_with(job: PantryScanJob) do
      post retry_analysis_pantry_scan_path(scan)
    end

    scan.reload
    assert_redirected_to pantry_scan_path(scan)
    assert scan.processing?
    assert_equal 2, scan.analysis_attempts
    assert_not_nil scan.analysis_token
    assert_equal scan.analysis_token, enqueued_jobs.last.fetch(:args).second
    assert scan.photos.attached?
  end

  test "ne relance pas une analyse deja traitee" do
    scan = @user.pantry_scans.create!(
      label: "Validation",
      status: "pending_review",
      detected_items: [{ name: "Tomate", category: "legume", quantity_text: "4" }],
      items_detected: 1,
      photos: [uploaded_image]
    )

    assert_no_enqueued_jobs do
      post retry_analysis_pantry_scan_path(scan)
    end

    assert_redirected_to pantry_scan_path(scan)
    assert_equal "pending_review", scan.reload.status
  end

  private

  def uploaded_image
    file = Tempfile.new(["frigo", ".png"])
    file.binmode
    file.write(Base64.decode64(PNG_BASE64))
    file.rewind

    Rack::Test::UploadedFile.new(file.path, "image/png")
  end
end
