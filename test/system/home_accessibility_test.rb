require "application_system_test_case"

class HomeAccessibilityTest < ApplicationSystemTestCase
  test "keeps hero actions and light surfaces readable in dark mode" do
    use_mobile_viewport
    visit root_path
    page.execute_script("document.documentElement.classList.add('dark')")

    assert_no_horizontal_overflow
    assert_minimum_touch_target "nav a.btn-primary"
    assert_minimum_touch_target ".da-shell .btn-primary"
    assert_minimum_touch_target ".da-shell .btn-secondary"
    assert_color_contrast "nav a.btn-primary"
    assert_color_contrast ".da-shell .btn-primary"
    assert_color_contrast ".da-shell .btn-secondary"
    assert_color_contrast ".da-shell .da-chip"
    assert_color_contrast ".da-shell .page-kicker", background_selector: ".da-shell"
    assert_color_contrast ".da-ticket"
  end
end
