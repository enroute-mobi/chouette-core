# frozen_string_literal: true

module ControlMacro
  # Notification support for scheduled Control::List::Run / Macro::List::Run.
  #
  # A run is scheduled when its Processing has no parent Operation (it has been created by a
  # ProcessingRule::Scheduling). Only these runs expose a notification_type (instead of the
  # Operation#notification_type default), so that operation-triggered runs don't match any
  # Notification Rule (see NotificationRule.for_operation).
  module Scheduled
    def notification_type
      'scheduled_processing' if scheduled?
    end

    def scheduled?
      processing.present? && processing.operation_id.nil?
    end
  end
end
