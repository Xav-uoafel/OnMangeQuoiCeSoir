require "base64"
require "test_helper"

class PantryScansControllerTest < ActionDispatch::IntegrationTest
  include ActiveJob::TestHelper

  PNG_BASE64 = "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVQIHWP4////fwAJ+wP9KobjigAAAABJRU5ErkJggg=="

  def setup
    @user = users(:one)
  end

  test "devrait afficher le formulaire de scan" do
    sign_in @user

    get new_pantry_scan_path

    assert_response :success
    assert_select "input[type=file][name='pantry_scan[photos][]']"
  end

  test "devrait creer un scan avec photo" do
    sign_in @user

    assert_enqueued_with(job: PantryScanJob) do
      assert_difference("PantryScan.count", 1) do
        post pantry_scans_path, params: {
          pantry_scan: {
            label: "Frigo semaine",
            photos: [uploaded_image]
          }
        }
      end
    end

    scan = PantryScan.last
    assert_redirected_to pantry_scan_path(scan)
    assert_equal "processing", scan.status
    assert scan.photos.attached?
    assert_not_nil scan.analysis_token
    assert_equal 1, scan.analysis_attempts
    assert_equal scan.analysis_token, enqueued_jobs.last.fetch(:args).second
  end

  test "ne devrait pas creer un scan sans photo" do
    sign_in @user

    assert_no_difference("PantryScan.count") do
      post pantry_scans_path, params: {
        pantry_scan: {
          label: "Sans photo"
        }
      }
    end

    assert_response :unprocessable_entity
  end

  test "devrait valider les ingredients detectes avant ajout au stock" do
    sign_in @user
    scan = @user.pantry_scans.create!(
      label: "Validation",
      status: "pending_review",
      detected_items: [{ name: "Tomate", category: "legume", quantity_text: "4" }],
      items_detected: 1,
      photos: [uploaded_image]
    )

    assert_difference("@user.pantry_items.count", 1) do
      post confirm_pantry_scan_path(scan), params: {
        detected_items: {
          "0" => {
            selected: "1",
            name: "Tomate",
            category: "legume",
            quantity_text: "4"
          }
        }
      }
    end

    assert_redirected_to pantry_scan_path(scan)
    assert_equal "completed", scan.reload.status
    assert_equal "tomate", @user.pantry_items.last.name
  end

  test "devrait ignorer un scan en attente" do
    sign_in @user
    scan = @user.pantry_scans.create!(
      label: "A ignorer",
      status: "pending_review",
      detected_items: [{ name: "Objet inconnu", category: "autre", quantity_text: "" }],
      items_detected: 1,
      photos: [uploaded_image]
    )

    assert_no_difference("@user.pantry_items.count") do
      post discard_pantry_scan_path(scan)
    end

    assert_redirected_to pantry_items_path
    assert_equal "discarded", scan.reload.status
    assert_empty scan.detected_items
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
