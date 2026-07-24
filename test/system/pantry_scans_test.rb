require "base64"
require "application_system_test_case"

class PantryScansTest < ApplicationSystemTestCase
  PNG_BASE64 = "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVQIHWP4////fwAJ+wP9KobjigAAAABJRU5ErkJggg==".freeze

  setup do
    sign_in_as users(:one)
    @image = Tempfile.new(["frigo", ".png"])
    @image.binmode
    @image.write(Base64.decode64(PNG_BASE64))
    @image.rewind

    @text_file = Tempfile.new(["notes", ".txt"])
    @text_file.write("pas une image")
    @text_file.rewind
  end

  teardown do
    @image.close!
    @text_file.close!
  end

  test "valide les photos avant envoi sur mobile" do
    use_mobile_viewport
    visit new_pantry_scan_path

    assert_no_horizontal_overflow
    assert_input_spacing "#pantry_scan_label"
    assert_button "Analyser les photos", disabled: true
    assert_minimum_touch_target "input[type='submit']"

    attach_file "Photos à analyser", @image.path, make_visible: true

    assert_text "1 photo prête à analyser"
    assert_button "Analyser les photos", disabled: false
    assert_selector "input[type='file'][aria-invalid='false']", visible: :all

    attach_file "Photos à analyser", @text_file.path, make_visible: true

    assert_text "n’est pas au format JPG, PNG ou WebP"
    assert_button "Analyser les photos", disabled: true
    assert_selector "input[type='file'][aria-invalid='true']", visible: :all
    assert_no_horizontal_overflow
  end
end
