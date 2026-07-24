require "test_helper"

class RequestRateLimiterTest < ActiveSupport::TestCase
  setup do
    @now = Time.zone.parse("2026-07-19 12:10:00")
  end

  test "refuse les appels au dela de la limite" do
    first = limiter(limit: 2).call
    second = limiter(limit: 2).call
    third = limiter(limit: 2).call

    assert first.allowed?
    assert second.allowed?
    assert_not third.allowed?
    assert_equal 3, RequestRateLimit.first.count
    assert_equal 3_000, third.retry_after
  end

  test "isole les utilisateurs et les operations" do
    limiter(identity: 1, scope: "scan", limit: 1).call

    assert limiter(identity: 2, scope: "scan", limit: 1).call.allowed?
    assert limiter(identity: 1, scope: "plan", limit: 1).call.allowed?
  end

  test "ouvre une nouvelle fenetre apres expiration" do
    assert limiter(limit: 1).call.allowed?
    assert_not limiter(limit: 1).call.allowed?

    next_window = @now + 1.hour
    assert limiter(limit: 1, now: next_window).call.allowed?
    assert_equal 2, RequestRateLimit.count
  end

  private

  def limiter(identity: 1, scope: "generation", limit: 2, now: @now)
    RequestRateLimiter.new(
      scope: scope,
      identity: identity,
      limit: limit,
      period: 1.hour,
      now: now
    )
  end
end
