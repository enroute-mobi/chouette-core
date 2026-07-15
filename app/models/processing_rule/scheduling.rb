# frozen_string_literal: true

module ProcessingRule
  # Schedule a ProcessingRule to be performed periodically.
  #
  # Like AggregateScheduling, a dedicated Delayed::Job (ScheduledJob) is created with a cron
  # expression derived from scheduled_time and scheduled_days (see SchedulingSupport). When the
  # job fires it:
  #   * selects the target (none, or the Workbench/Workgroup output current Referential)
  #   * performs the rule's Control or Macro
  #   * lets the resulting Run invoke its associated Notification Rules
  class Scheduling < ApplicationModel
    self.table_name = 'processing_rule_schedulings'

    extend Enumerize
    include SchedulingSupport

    belongs_to :processing_rule, class_name: 'ProcessingRule::Base', inverse_of: :schedulings

    schedule_by :scheduled_time, :scheduled_days

    # Referential used to perform the Control/Macro:
    #   none    -> no Referential (e.g. controls/macros running on Stop Areas)
    #   current -> the Workbench/Workgroup output current Referential (merged for a
    #              Workbench, aggregated for a Workgroup)
    #   merged  -> Workgroup only: fans out over the targeted Workbenches, running on
    #              each Workbench own merged output current Referential
    enumerize :target, in: %w[none current merged], default: :none

    validate :target_must_be_in_candidates

    delegate :scheduling_workbench, to: :processing_rule

    private

    # 'merged' is only supported by Workgroup Processing Rules
    def target_must_be_in_candidates
      return unless processing_rule
      return if target.in?(processing_rule.candidate_scheduling_targets)

      errors.add(:target, :inclusion)
    end

    class ScheduledJob < SchedulingSupport::ScheduledJob
      def encode_with(coder)
        coder['processing_rule_scheduling_id'] = scheduling.id
      end

      def init_with(coder)
        @scheduling = ProcessingRule::Scheduling.find(coder['processing_rule_scheduling_id'])
      end

      def perform
        scheduling.processing_rule.scheduled_perform_args(scheduling.target).each do |operation_workbench, referential|
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
