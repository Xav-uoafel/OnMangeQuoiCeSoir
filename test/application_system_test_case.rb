require "test_helper"
require "warden/test/helpers"

class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  include ActiveJob::TestHelper
  include Warden::Test::Helpers

  COLOR_CONTRAST_SCRIPT = Rails.root.join("test/support/color_contrast.js").read.freeze

  driven_by :selenium, using: :headless_chrome, screen_size: [1400, 1000] do |options|
    options.add_preference("credentials_enable_service", false)
    options.add_preference("profile.password_manager_enabled", false)
  end

  setup do
    Warden.test_mode!
  end

  teardown do
    Warden.test_reset!
  end

  private

  def sign_in_as(user)
    login_as(user, scope: :user)
  end

  def use_mobile_viewport
    page.current_window.resize_to(390, 844)
  end

  def assert_no_horizontal_overflow
    dimensions = page.evaluate_script(<<~JAVASCRIPT)
      ({
        contentWidth: document.documentElement.scrollWidth,
        viewportWidth: window.innerWidth
      })
    JAVASCRIPT

    assert_operator dimensions.fetch("contentWidth"), :<=, dimensions.fetch("viewportWidth") + 1
  end

  def assert_elements_do_not_overlap(left_selector, right_selector)
    positions = page.evaluate_script(<<~JAVASCRIPT)
      (() => {
        const left = document.querySelector(#{left_selector.to_json}).getBoundingClientRect();
        const right = document.querySelector(#{right_selector.to_json}).getBoundingClientRect();
        return { leftEdge: left.right, rightEdge: right.left };
      })()
    JAVASCRIPT

    assert_operator positions.fetch("leftEdge"), :<=, positions.fetch("rightEdge")
  end

  def assert_minimum_touch_target(selector)
    dimensions = page.evaluate_script(<<~JAVASCRIPT)
      (() => {
        const rect = document.querySelector(#{selector.to_json}).getBoundingClientRect();
        return { width: rect.width, height: rect.height };
      })()
    JAVASCRIPT

    assert_operator dimensions.fetch("width"), :>=, 44
    assert_operator dimensions.fetch("height"), :>=, 44
  end

  def assert_input_spacing(selector)
    spacing = page.evaluate_script(<<~JAVASCRIPT)
      (() => {
        const input = document.querySelector(#{selector.to_json});
        const styles = window.getComputedStyle(input);
        return {
          paddingLeft: parseFloat(styles.paddingLeft),
          paddingRight: parseFloat(styles.paddingRight),
          height: input.getBoundingClientRect().height
        };
      })()
    JAVASCRIPT

    assert_operator spacing.fetch("paddingLeft"), :>=, 12
    assert_operator spacing.fetch("paddingRight"), :>=, 12
    assert_operator spacing.fetch("height"), :>=, 44
  end

  def assert_below_initial_viewport(selector)
    position = page.evaluate_script(<<~JAVASCRIPT)
      (() => ({
        elementTop: document.querySelector(#{selector.to_json}).getBoundingClientRect().top,
        viewportHeight: window.innerHeight
      }))()
    JAVASCRIPT

    assert_operator position.fetch("elementTop"), :>=, position.fetch("viewportHeight")
  end

  def assert_color_contrast(foreground_selector, background_selector: foreground_selector, minimum: 4.5)
    result = page.evaluate_script(<<~JAVASCRIPT)
      (#{COLOR_CONTRAST_SCRIPT})(
        #{foreground_selector.to_json},
        #{background_selector.to_json}
      )
    JAVASCRIPT

    message = "Contraste #{result.fetch('foreground')} sur #{result.fetch('background')}"
    assert_operator result.fetch("ratio"), :>=, minimum, message
  end
end
