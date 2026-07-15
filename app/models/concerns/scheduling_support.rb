# frozen_string_literal: true

# Factorizes models which schedule a dedicated Delayed::Job (ScheduledJob) with a cron
# expression derived from a time-of-day and days-of-week pair, like AggregateScheduling
# and ProcessingRule::Scheduling:
#
#   class AggregateScheduling < ApplicationModel
#     include SchedulingSupport
#
#     schedule_by :aggregate_time, :aggregate_days
#
#     class ScheduledJob < SchedulingSupport::ScheduledJob
#       # defines encode_with / init_with / perform
#     end
#   end
module SchedulingSupport
  extend ActiveSupport::Concern

  included do
    belongs_to :scheduled_job, class_name: '::Delayed::Job', optional: true

    after_commit :reschedule, on: %i[create update], if: :reschedule_needed?
    after_commit :destroy_scheduled_job, on: :destroy
  end

  class_methods do
    attr_reader :schedule_time_attribute, :schedule_days_attribute

    # Declares the attributes providing the time-of-day and days-of-week
    # used to build the ScheduledJob cron expression
    def schedule_by(time_attribute, days_attribute)
      @schedule_time_attribute = time_attribute
      @schedule_days_attribute = days_attribute

      attribute time_attribute, TimeOfDay::Type::TimeWithoutZone.new
      attribute days_attribute, Cuckoo::DaysOfWeek::Type.new

      validate :validate_presence_of_schedule_days
    end
  end

  def schedule_time
    send(self.class.schedule_time_attribute)
  end

  def schedule_days
    send(self.class.schedule_days_attribute)
  end

  def next_schedule
    scheduled_job&.run_at
  end

  def reschedule
    job = self.class::ScheduledJob.new(self)

    if scheduled_job
      scheduled_job.update(cron: job.cron)
    else
      delayed_job = Delayed::Job.enqueue(job, cron: job.cron)
      update_column(:scheduled_job_id, delayed_job.id) # rubocop:disable Rails/SkipsModelValidations
    end
  end

  private

  def validate_presence_of_schedule_days
    return unless schedule_days.none?

    errors.add(self.class.schedule_days_attribute, :blank)
  end

  def reschedule_needed?
    saved_change_to_id? ||
      saved_change_to_attribute?(self.class.schedule_time_attribute) ||
      saved_change_to_attribute?(self.class.schedule_days_attribute)
  end

  def destroy_scheduled_job
    scheduled_job&.destroy
  end

  # Base class of the Delayed::Job payload created by the scheduling model
  class ScheduledJob < ::ScheduledJob
    def initialize(scheduling)
      super()
      @scheduling = scheduling
    end
    attr_reader :scheduling

    def cron
      [
        scheduling.schedule_time.minute,
        scheduling.schedule_time.hour,
        '*',
        '*',
        scheduling.schedule_days.to_cron
      ].join(' ')
    end
  end
end
