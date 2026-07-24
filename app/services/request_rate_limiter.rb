require "digest"

class RequestRateLimiter
  Result = Data.define(:allowed, :retry_after) do
    def allowed?
      allowed
    end
  end

  def initialize(scope:, identity:, limit:, period:, now: Time.current)
    @scope = scope
    @identity = identity
    @limit = limit
    @period_seconds = period.to_i
    @now = now
  end

  def call
    validate_configuration!
    record = find_or_create_record
    count = record.with_lock do
      record.count += 1
      record.save!
      record.count
    end

    Result.new(
      allowed: count <= @limit,
      retry_after: [(record.expires_at - @now).ceil, 1].max
    )
  end

  private

  def validate_configuration!
    return if @scope.present? && @identity.present? && @limit.positive? && @period_seconds.positive?

    raise ArgumentError, "Configuration de limite invalide"
  end

  def find_or_create_record
    RequestRateLimit.create_or_find_by!(key: bucket_key) do |record|
      record.count = 0
      record.window_started_at = window_started_at
      record.expires_at = window_started_at + @period_seconds
    end
  end

  def bucket_key
    Digest::SHA256.hexdigest([@scope, @identity, window_started_at.to_i].join(":"))
  end

  def window_started_at
    @window_started_at ||= Time.zone.at((@now.to_i / @period_seconds) * @period_seconds)
  end
end
