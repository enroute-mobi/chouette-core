# frozen_string_literal: true

class AggregateScheduling < ApplicationModel
  include SchedulingSupport

  belongs_to :workgroup # CHOUETTE-3247 optional: false

  schedule_by :aggregate_time, :aggregate_days

  validates :force_daily_publishing, inclusion: [true, false]

  class ScheduledJob < SchedulingSupport::ScheduledJob
    alias aggregate_scheduling scheduling

    def encode_with(coder)
      coder['aggregate_scheduling_id'] = aggregate_scheduling.id
    end

    def init_with(coder)
      @scheduling = AggregateScheduling.find(coder['aggregate_scheduling_id'])
    end

    def perform
      aggregate_scheduling.workgroup.aggregate!(
        daily_publications: aggregate_scheduling.force_daily_publishing
      )
    end

    protected

    def perform_error_capture_message
      "Can't start AggregateScheduling##{aggregate_scheduling.id}::ScheduledJob"
    end
  end
end
