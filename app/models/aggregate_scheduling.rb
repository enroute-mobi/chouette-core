# frozen_string_literal: true

class AggregateScheduling < ApplicationModel
  belongs_to :workgroup, optional: false
  belongs_to :scheduled_job, class_name: '::Delayed::Job', optional: true

  attribute :aggregate_time, TimeOfDay::Type::TimeWithoutZone.new
  attribute :aggregate_days, WeekDays.new

  validates :force_daily_publishing, inclusion: [true, false]
  validate :validate_presence_of_aggregate_days

  after_commit :reschedule, on: %i[create update], if: :reschedule_needed?
  after_commit :destroy_scheduled_job, on: :destroy

  def next_schedule
    scheduled_job&.run_at
  end

  def reschedule
    job = ScheduledJob.new(self)

    if scheduled_job
      scheduled_job.update(cron: job.cron)
    else
      delayed_job = Delayed::Job.enqueue(job, cron: job.cron)
      update_column(:scheduled_job_id, delayed_job.id) # rubocop:disable Rails/SkipsModelValidations
    end
  end

  private

  def validate_presence_of_aggregate_days
    return unless aggregate_days.none?

    errors.add(:aggregate_days, :blank)
  end

  def reschedule_needed?
    saved_change_to_id? || saved_change_to_aggregate_time? || saved_change_to_aggregate_days?
  end

  def destroy_scheduled_job
    scheduled_job&.destroy
  end

  class ScheduledJob < ::ScheduledJob
    def initialize(aggregate_scheduling)
      super()
      @aggregate_scheduling = aggregate_scheduling
    end
    attr_reader :aggregate_scheduling

    def encode_with(coder)
      coder['aggregate_scheduling_id'] = aggregate_scheduling.id
    end

    def init_with(coder)
      @aggregate_scheduling = AggregateScheduling.find(coder['aggregate_scheduling_id'])
    end

    def cron
      [
        aggregate_scheduling.aggregate_time.minute,
        aggregate_scheduling.aggregate_time.hour,
        '*',
        '*',
        aggregate_scheduling.aggregate_days.to_cron
      ].join(' ')
    end

    def perform
      aggregate_scheduling.workgroup.aggregate!(
        force_daily_publishing: aggregate_scheduling.force_daily_publishing
      )
    end

    protected

    def perform_error_capture_message
      "Can't start AggregateScheduling##{aggregate_scheduling.id}::ScheduledJob"
    end
  end
end
