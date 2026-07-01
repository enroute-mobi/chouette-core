# frozen_string_literal: true

module ProcessingRule
  # Schedule a ProcessingRule to be performed periodically.
  #
  # Like AggregateScheduling, a dedicated Delayed::Job (ScheduledJob) is created with a cron
  # expression derived from scheduled_time and scheduled_days. When the job fires it:
  #   * selects the target (none, or the Workbench/Workgroup output current Referential)
  #   * performs the rule's Control or Macro
  #   * lets the resulting Run invoke its associated Notification Rules
  class Scheduling < ApplicationModel
    self.table_name = 'processing_rule_schedulings'

    extend Enumerize

    belongs_to :processing_rule, class_name: 'ProcessingRule::Base', inverse_of: :schedulings
    belongs_to :scheduled_job, class_name: '::Delayed::Job', optional: true

    attribute :scheduled_time, TimeOfDay::Type::TimeWithoutZone.new
    attribute :scheduled_days, Cuckoo::DaysOfWeek::Type.new

    # Referential used to perform the Control/Macro:
    #   none    -> no Referential (e.g. controls/macros running on Stop Areas)
    #   current -> the Workbench/Workgroup output current Referential (merged for a
    #              Workbench, aggregated for a Workgroup)
    #   merged  -> Workgroup only: fans out over the targeted Workbenches, running on
    #              each Workbench own merged output current Referential
    enumerize :target, in: %w[none current merged], default: :none

    validate :validate_presence_of_scheduled_days

    after_commit :reschedule, on: %i[create update], if: :reschedule_needed?
    after_commit :destroy_scheduled_job, on: :destroy

    delegate :scheduling_workbench, to: :processing_rule

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

    def target_referential
      return nil unless target == 'current'

      processing_rule.output_current_referential
    end

    private

    def validate_presence_of_scheduled_days
      return unless scheduled_days.none?

      errors.add(:scheduled_days, :blank)
    end

    def reschedule_needed?
      saved_change_to_id? || saved_change_to_scheduled_time? || saved_change_to_scheduled_days?
    end

    def destroy_scheduled_job
      scheduled_job&.destroy
    end

    class ScheduledJob < ::ScheduledJob
      def initialize(scheduling)
        super()
        @scheduling = scheduling
      end
      attr_reader :scheduling

      def encode_with(coder)
        coder['processing_rule_scheduling_id'] = scheduling.id
      end

      def init_with(coder)
        @scheduling = ProcessingRule::Scheduling.find(coder['processing_rule_scheduling_id'])
      end

      def cron
        [
          scheduling.scheduled_time.minute,
          scheduling.scheduled_time.hour,
          '*',
          '*',
          scheduling.scheduled_days.to_cron
        ].join(' ')
      end

      def perform
        scheduling.processing_rule.scheduled_executions(scheduling.target).each do |operation_workbench, referential|
          scheduling.processing_rule.perform(referential: referential, operation_workbench: operation_workbench)
        end
      end

      protected

      def perform_error_capture_message
        "Can't start ProcessingRule::Scheduling##{scheduling.id}::ScheduledJob"
      end
    end
  end
end
