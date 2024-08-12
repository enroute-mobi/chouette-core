# frozen_string_literal: true

class ScheduledJob
  include AroundMethod

  def cron
    raise NotImplementedError
  end

  around_method :perform
  def around_perform(&block)
    block.call
  rescue StandardError => e
    Chouette::Safe.capture perform_error_capture_message, e
  end

  protected

  def perform_error_capture_message
    "Can't start ScheduledJob"
  end
end
