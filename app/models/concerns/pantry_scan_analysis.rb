module PantryScanAnalysis
  extend ActiveSupport::Concern

  def start_analysis!
    token = SecureRandom.uuid

    with_lock do
      update!(
        status: "processing",
        analysis_token: token,
        analysis_started_at: Time.current,
        analysis_completed_at: nil,
        analysis_error_code: nil,
        analysis_attempts: analysis_attempts.to_i + 1,
        detected_items: [],
        items_detected: 0
      )
    end

    token
  end

  def current_analysis?(token)
    processing? && token.present? && analysis_token == token
  end

  def complete_analysis!(token, detected_items:)
    transition_analysis(
      token,
      status: "pending_review",
      detected_items: detected_items,
      items_detected: detected_items.size,
      analysis_completed_at: Time.current,
      analysis_error_code: nil
    )
  end

  def fail_analysis!(token, code: "technical_error")
    transition_analysis(
      token,
      status: "failed",
      analysis_completed_at: Time.current,
      analysis_error_code: code
    )
  end

  def analysis_stale?(now: Time.current)
    return false unless processing?

    analysis_started_at.blank? || analysis_started_at < now - self.class::ANALYSIS_TIMEOUT
  end

  def analysis_retryable?
    failed? || analysis_stale?
  end

  def analysis_error_message
    code = analysis_stale? ? "timeout" : analysis_error_code
    messages = self.class::ANALYSIS_ERROR_MESSAGES
    messages.fetch(code, messages.fetch("technical_error"))
  end

  private

  def transition_analysis(token, attributes)
    transitioned = false

    with_lock do
      if current_analysis?(token)
        update!(attributes.merge(analysis_token: nil))
        transitioned = true
      end
    end

    transitioned
  end
end
