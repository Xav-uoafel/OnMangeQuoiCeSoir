require "base64"
require "test_helper"

class PantryScanJobTest < ActiveJob::TestCase
  PNG_BASE64 = "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVQIHWP4////fwAJ+wP9KobjigAAAABJRU5ErkJggg=="

  FakeDetector = Struct.new(:ingredients) do
    def detect
      ingredients
    end
  end

  test "stocke les ingredients detectes en attente de validation" do
    user = users(:one)
    user.pantry_items.create!(
      name: "tomates",
      category: "legume",
      quantity_text: "2",
      detected_on: Date.yesterday,
      source: "manual"
    )
    scan = user.pantry_scans.create!(label: "Frigo", photos: [valid_image_attachment])
    detector = FakeDetector.new([
      { name: "Tomate", category: "legume", quantity_text: "4" }
    ])
    analysis_token = scan.start_analysis!
    image_sources = nil

    original_detector = LLM::IngredientDetector.method(:new)
    LLM::IngredientDetector.define_singleton_method(:new) do |sources|
      image_sources = sources
      detector
    end

    begin
      assert_no_difference("user.pantry_items.count") do
        PantryScanJob.perform_now(scan.id, analysis_token)
      end
    ensure
      LLM::IngredientDetector.define_singleton_method(:new, original_detector)
    end

    scan.reload
    item = user.pantry_items.find_by!(name: "tomates")
    assert_equal "pending_review", scan.status
    assert_equal 1, scan.items_detected
    assert_equal "2", item.quantity_text
    assert_nil item.pantry_scan
    assert_equal "Tomate", scan.detected_items.first["name"]
    assert_equal "4", scan.detected_items.first["quantity_text"]
    assert_match(%r{\Adata:image/png;base64,}, image_sources.first)
    assert_nil scan.analysis_token
  end

  test "ignore une ancienne tentative apres relance" do
    scan = users(:one).pantry_scans.create!(label: "Frigo", photos: [valid_image_attachment])
    old_token = scan.start_analysis!
    current_token = scan.start_analysis!
    detector_called = false

    original_detector = LLM::IngredientDetector.method(:new)
    LLM::IngredientDetector.define_singleton_method(:new) do |_sources|
      detector_called = true
      FakeDetector.new([])
    end

    begin
      PantryScanJob.perform_now(scan.id, old_token)
    ensure
      LLM::IngredientDetector.define_singleton_method(:new, original_detector)
    end

    scan.reload
    assert_not detector_called
    assert scan.current_analysis?(current_token)
    assert_equal "processing", scan.status
  end

  test "enregistre une erreur de detection relancable" do
    scan = users(:one).pantry_scans.create!(label: "Frigo", photos: [valid_image_attachment])
    analysis_token = scan.start_analysis!
    error = LLM::IngredientDetector::DetectionError.new(
      "Service indisponible",
      code: "service_unavailable",
      retryable: true
    )
    detector = Object.new
    detector.define_singleton_method(:detect) { raise error }

    original_detector = LLM::IngredientDetector.method(:new)
    LLM::IngredientDetector.define_singleton_method(:new) { |_sources| detector }

    begin
      PantryScanJob.perform_now(scan.id, analysis_token)
    ensure
      LLM::IngredientDetector.define_singleton_method(:new, original_detector)
    end

    scan.reload
    assert scan.failed?
    assert_equal "service_unavailable", scan.analysis_error_code
    assert_nil scan.analysis_token
  end

  private

  def valid_image_attachment
    {
      io: StringIO.new(Base64.decode64(PNG_BASE64)),
      filename: "frigo.png",
      content_type: "image/png"
    }
  end
end
