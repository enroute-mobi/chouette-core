# frozen_string_literal: true

module Macro
  class List < ApplicationModel
    self.table_name = 'macro_lists'

    belongs_to :workbench # CHOUETTE-3247 optional: false
    validates :name, presence: true

    with_options(inverse_of: :macro_list, foreign_key: 'macro_list_id') do
      has_many :macros, -> { order(position: :asc) }, class_name: 'Macro::Base', dependent: :delete_all
      has_many :macro_contexts, class_name: 'Macro::Context', dependent: :destroy
    end

    has_many :processing_rules, class_name: 'ProcessingRule::Base', as: :processable
    has_many :macro_list_runs, class_name: 'Macro::List::Run', foreign_key: :original_macro_list_id

    accepts_nested_attributes_for :macros, allow_destroy: true, reject_if: :all_blank
    accepts_nested_attributes_for :macro_contexts, allow_destroy: true, reject_if: :all_blank

    scope :by_text, ->(text) { text.blank? ? all : where('lower(name) LIKE :t', t: "%#{text.downcase}%") }

    def used?
      processing_rules.exists?
    end

    # macro_list_run = macro_list.build_run user: user, workbench: workbench, referential: target
    #
    # if macro_list_run.save
    #   macro_list_run.enqueue
    # else
    #   render ...
    # end

    concerning :Processable do
      include ::ControlMacro::Processable

      class_methods do
        def candidate_operation_steps
          %w[after_import before_merge]
        end
      end
    end

    class ProcessingBuilder < ::ControlMacro::ProcessingBuilder
      protected

      def build_processed
        processable.macro_list_runs.new(processed_attributes).tap do |processed|
          processed.build_with_original_macro_list
        end
      end
    end

    class Run < Operation
      # The Workbench where macros are executed
      self.table_name = 'macro_list_runs'

      belongs_to :workbench # CHOUETTE-3247 optional: false
      delegate :workgroup, to: :workbench

      # The Referential where macros are executed.
      # Optional, because the user can run macros on Stop Areas for example
      belongs_to :referential, optional: true # CHOUETTE-3247

      # The original macro list definition. This macro list can have been modified or deleted since.
      # Should only used to provide a link in the UI
      belongs_to :original_macro_list, optional: true, foreign_key: :original_macro_list_id, class_name: 'Macro::List' # CHOUETTE-3247

      with_options(foreign_key: 'macro_list_run_id', dependent: :destroy, inverse_of: :macro_list_run) do
        has_many :macro_runs, -> { order(position: :asc) }, class_name: 'Macro::Base::Run'
        has_many :macro_context_runs, class_name: 'Macro::Context::Run'
      end
      has_many :macro_messages, class_name: 'Macro::Message', through: :macro_runs
      has_many :context_macro_messages,
               class_name: 'Macro::Message',
               through: :macro_context_runs,
               source: :macro_messages

      has_one :processing, as: :processed

      validates :name, presence: true
      validates :original_macro_list_id, presence: true, if: :new_record?

      scope :purgeable, -> { where("created_at < ?", 90.days.ago) }

      def purge_older
        workbench.macro_list_runs.purgeable.in_batches.destroy_all if workbench
      end

      after_create :purge_older

      def build_with_original_macro_list
        return unless original_macro_list

        original_macro_list.macros.each do |macro|
          macro_runs << macro.build_run
        end

        original_macro_list.macro_contexts.each do |macro_context|
          macro_context_runs << macro_context.build_run
        end
      end

      def perform
        referential.switch if referential

        macro_runs.each(&:run)
        macro_context_runs.each(&:run)
      end

      def final_user_status
        UserStatusFinalizer.new(self).user_status
      end

      class UserStatusFinalizer
        def initialize(macro_list_run)
          @macro_list_run = macro_list_run
        end
        attr_reader :macro_list_run

        delegate :macro_messages, :context_macro_messages, to: :macro_list_run

        def criticities
          @criticities ||= (without_context_criticities + with_context_criticities).uniq
        end

        def worst_criticity
          %w[error warning].find do |criticity|
            criticity.in?(criticities)
          end
        end

        def user_status
          case worst_criticity
          when 'error'
            Operation.user_status.failed
          when 'warning'
            Operation.user_status.warning
          else
            Operation.user_status.successful
          end
        end

        private

        def without_context_criticities
          # reorder! to avoid problems with default order and pluck
          macro_messages.reorder!.distinct.pluck(:criticity)
        end

        def with_context_criticities
          context_macro_messages.reorder!.distinct.pluck(:criticity)
        end
      end

      def base_scope
        if referential
          Scope::Referential.new(workbench, referential)
        else
          Scope::Workbench.new(workbench)
        end
      end

      def owned_scope
        Scope::Owned.new(base_scope, workbench)
      end

      def scope
        owned_scope
      end
    end
  end
end
