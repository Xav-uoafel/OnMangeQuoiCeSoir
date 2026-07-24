require "test_helper"

class RequestRateLimitingTest < ActionDispatch::IntegrationTest
  Result = RequestRateLimiter::Result

  setup do
    @user = users(:one)
    sign_in @user
  end

  test "retourne une page accessible et un delai sans lancer l operation" do
    limiter = Object.new
    limiter.define_singleton_method(:call) { Result.new(allowed: false, retry_after: 420) }
    original_limiter = RequestRateLimiter.method(:new)
    RequestRateLimiter.define_singleton_method(:new) { |**_options| limiter }

    assert_no_difference("Plan.count") do
      post plans_path, params: { plan: {} }
    end

    assert_response :too_many_requests
    assert_equal "420", response.headers["Retry-After"]
    assert_equal "no-store", response.headers["Cache-Control"]
    assert_select "h1", "Un peu de patience"
    assert_select "a", "Revenir à l’accueil"
  ensure
    RequestRateLimiter.define_singleton_method(:new, original_limiter) if original_limiter
  end
end
