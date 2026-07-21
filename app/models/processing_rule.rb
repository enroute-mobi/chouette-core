# frozen_string_literal: true

module ProcessingRule
  # Base model to define Workbench and Workgroup ProcessingRule
  class Base < ApplicationModel
    self.table_name = :processing_rules

    extend Enumerize
    include TagsSupport
    include SchedulingSupport

    # Macro::List or Control::List to be started
    belongs_to :processable, polymorphic: true, optional: true
    has_many :processings, foreign_key: 'processing_rule_id'

    has_tags :required_tags
    has_tags :excluded_tags

    schedule_by :scheduling_time, :scheduling_days

    # Referential used to perform the Control/Macro:
    #   none    -> no Referential (e.g. controls/macros running on Stop Areas)
    #   current -> the Workbench/Workgroup output current Referential (merged for a
    #              Workbench, aggregated for a Workgroup)
    #   merged  -> Workgroup only: fans out over the targeted Workbenches, running on
    #              each Workbench own merged output current Referential
    enumerize :scheduling_target, in: %w[none current merged], default: :none

    validates :operation_step, :processable_type, :processable_id, presence: true
    validates :control_list_id, presence: true, if: :use_control_list?
    validates :scheduling_target, inclusion: { in: ->(rule) { rule.candidate_scheduling_targets } }
    validates :processable, inclusion: { in: ->(rule) { rule.candidate_control_lists } }, if: :use_control_list?
    validates :operation_step, inclusion: { in: ->(rule) { rule.candidate_operation_steps } }

    validate :required_tags_must_be_in_candidates
    validate :excluded_tags_must_be_in_candidates
    validate :no_tag_overlap

    def use_control_list?
      processable_type == Control::List.name
    end

    def after_import?
      operation_step == :after_import
    end

    def scheduling?
      operation_step == :scheduling
    end

    # Operation steps allowing several rules for the same processable_type, told apart by their
    # processable_id: after_import (differ by tags/list) and scheduling (differ by list). The same
    # processable may then be used by both an after_import and a scheduling rule (the uniqueness
    # applies to rules sharing the same operation_step), and a scheduling rule can hold several
    # schedulings.
    def unique_per_processable?
      after_import? || scheduling?
    end

    def control_list_id
      processable_id if use_control_list?
    end

    def control_list_id=(control_list_id)
      self.processable_id = control_list_id
    end

    def perform(**options)
      processable.create_processing(self, **options).perform
    end

    # Workbench/Workgroup specific. Workbench where scheduled Control/Macro runs are executed.
    def scheduling_workbench
      raise NotImplementedError
    end

    # Workbench/Workgroup specific. Output current Referential used by scheduled runs (target: current).
    def output_current_referential
      raise NotImplementedError
    end

    # [operation_workbench, referential] arguments for each #perform invoked by a scheduled run
    # with the given target (see ProcessingRule::Scheduling::ScheduledJob#perform).
    # A single invocation by default ; ProcessingRule::Workgroup fans out with target 'merged'.
    def scheduled_perform_args
      return [] if scheduling_target == 'current' && output_current_referential.nil?

      [[scheduling_workbench, output_current_referential]]
    end

    # Scheduling targets available for this rule ('merged' is Workgroup specific)
    def candidate_scheduling_targets
      %w[none current]
    end

    def candidate_operation_steps
      (processable&.class&.candidate_operation_steps || []) & self.class.operation_step.values
    end

    def candidate_tags
      raise NotImplementedError
    end

    def self.compatible_with_operation_via_tags(operation_step, tag_ids)
      CompatibleWithOperationViaTags.new(self, operation_step, tag_ids).query
    end

    class CompatibleWithOperationViaTags < ActiveRecord::Relation
      def initialize(scope, operation_step, tag_ids)
        @scope = scope
        @operation_step = operation_step
        @tag_ids = tag_ids
      end
      attr_reader :scope, :operation_step, :tag_ids

      def query
        scope
          .left_joins(:taggings)
          .where(operation_step: operation_step)
          .order(processable_type: :desc)
          .group(:id)
          .having(required_tags_condition, tag_ids)
          .having(excluded_tags_condition, tag_ids)
      end

      def required_tags_condition
        <<~SQL
          ((array_agg(taggings.tag_id) FILTER (WHERE taggings.for_association = 'required_tags'))::int[] && ARRAY[?]::int[])
          OR ((array_agg(taggings.tag_id) FILTER (WHERE taggings.for_association = 'required_tags')) IS NULL)
        SQL
      end

      def excluded_tags_condition
        <<~SQL
          NOT(
            (array_agg(taggings.tag_id) FILTER (WHERE taggings.for_association = 'excluded_tags'))::int[] && ARRAY[?]::int[]
          )
          OR ((array_agg(taggings.tag_id) FILTER (WHERE taggings.for_association = 'excluded_tags')) IS NULL)
        SQL
      end
    end

    private

    def no_tag_overlap
      return unless (required_tag_ids & excluded_tag_ids).any?

      errors.add(:required_tag_ids, :required_and_excluded_tags_cannot_overlap)
      errors.add(:excluded_tag_ids, :required_and_excluded_tags_cannot_overlap)
    end

    %i[excluded_tags required_tags].each do |association|
      define_method("#{association}_must_be_in_candidates") do
        return if send(association).blank? || (send(association) - candidate_tags).none?

        errors.add(association, :contain_invalid_tags)
      end
    end

    class ScheduledJob < SchedulingSupport::ScheduledJob
      def encode_with(coder)
        coder['processing_rule_id'] = scheduling.id
      end

      def init_with(coder)
        @scheduling = ::ProcessingRule::Base.find(coder['processing_rule_id'])
      end

      def perform
        scheduling.scheduled_perform_args.each do |operation_workbench, referential|
          scheduling.perform(operation_workbench: operation_workbench, referential: referential)
        end
      end

      protected

      def perform_error_capture_message
        "Can't start #{processing_rule.class.name}##{processing_rule.id}::ScheduledJob"
      end
    end
  end

  # Workbench ProcessingRule managed as Workbench#processing_rules
  class Workbench < Base
    belongs_to :workbench # CHOUETTE-3247 required: true

    enumerize :processable_type, in: %w[Macro::List Control::List]
    enumerize :operation_step, in: %w[after_import before_merge after_merge scheduling],
                               scope: :shallow,
                               i18n_scope: 'enumerize.processing_rule/base.operation_step'

    validates :operation_step, uniqueness: { scope: %i[processable_type workbench] }, unless: :unique_per_processable?
    validates :operation_step,
              uniqueness: { scope: %i[processable_type processable_id workbench] },
              if: :unique_per_processable?

    def use_macro_list?
      processable_type == Macro::List.name
    end

    def macro_list_id
      processable_id if use_macro_list?
    end

    def macro_list_id=(macro_list_id)
      self.processable_id = macro_list_id
    end

    def candidate_macro_lists
      workbench&.macro_lists || Macro::List.none
    end

    validates :macro_list_id, presence: true, if: :use_macro_list?
    validates :processable, inclusion: { in: ->(rule) { rule.candidate_macro_lists } }, if: :use_macro_list?

    def candidate_control_lists
      workbench&.control_lists_shared_with_workgroup || Control::List.none
    end

    def candidate_tags
      return Tag.none unless workbench

      workbench.tags
    end

    def scheduling_workbench
      workbench
    end

    def output_current_referential
      workbench.output.current
    end
  end

  # Workgroup ProcessingRule managed as Workgroup#processing_rules
  class Workgroup < Base
    belongs_to :workgroup # CHOUETTE-3247 required: true
    has_array_of :target_workbenches, class_name: 'Workbench'
    has_array_of :excluded_workbenches, class_name: 'Workbench'

    enumerize :processable_type, in: %w[Control::List Flamingo::ValidationSetup]
    enumerize :operation_step, in: %w[before_import after_import before_merge after_merge after_aggregate scheduling],
                               scope: :shallow,
                               i18n_scope: 'enumerize.processing_rule/base.operation_step'

    validates :operation_step, uniqueness: { scope: %i[processable_type workgroup] }, unless: :unique_per_processable?
    validates :operation_step,
              uniqueness: { scope: %i[processable_type processable_id workgroup] },
              if: :unique_per_processable?

    validate :exclusive_workbenches

    def candidate_control_lists
      workgroup ? workgroup.control_lists.shared : Control::List.none
    end

    def candidate_flamingo_validation_setups
      workgroup.flamingo_validation_setups
    end

    def candidate_target_workbenches
      workgroup.workbenches
    end

    def candidate_tags
      workgroup.tags
    end

    def scheduling_workbench
      workgroup.owner_workbench
    end

    def output_current_referential
      workgroup.output.current
    end

    # #scheduling_target 'merged': run the Control List on each targeted Workbench own merged output if it exists,
    # producing one Run per Workbench (visible on both the Workbench and Workgroup runs pages).
    def scheduled_perform_args
      if scheduling_target == 'merged'
        scheduled_merged_operation_workbenches.filter_map do |workbench|
          next nil unless workbench.output.current

          [workbench, workbench.output.current]
        end
      else
        super
      end
    end

    def candidate_scheduling_targets
      super + %w[merged]
    end

    # Workbenches a scheduled 'merged' run fans out to: targeted (or all) minus excluded.
    def scheduled_merged_operation_workbenches
      scope = workgroup.workbenches
      scope = scope.where(id: target_workbench_ids) if target_workbench_ids.present?
      scope = scope.where.not(id: excluded_workbench_ids) if excluded_workbench_ids.present?
      scope
    end

    def self.accept_workbench(workbench)
      where(
        'ARRAY_LENGTH(target_workbench_ids, 1) IS NULL OR target_workbench_ids && ARRAY[:workbench]::bigint[]',
        workbench: workbench
      )
      .where.not(
        'ARRAY_LENGTH(excluded_workbench_ids, 1) IS NOT NULL AND (excluded_workbench_ids && ARRAY[:workbench]::bigint[])',
        workbench: workbench
      )
    end

    private

    def exclusive_workbenches
      if target_workbench_ids.present? && excluded_workbench_ids.present?
        errors.add(:excluded_workbenches, :must_exclusive_between_target_and_excluded_workbenches)
      end
    end
  end
end
