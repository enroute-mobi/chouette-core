module Control
  class List < ApplicationModel
    self.table_name = 'control_lists'

    belongs_to :workbench, optional: false
    validates :name, presence: true

    with_options(inverse_of: :control_list) do
      with_options(foreign_key: 'control_list_id') do
        has_many :controls, -> { order(position: :asc) }, class_name: 'Control::Base', dependent: :delete_all
        has_many :control_contexts, class_name: 'Control::Context', dependent: :destroy
      end
    end

    has_many :control_list_runs, class_name: 'Control::List::Run', foreign_key: :original_control_list_id

    accepts_nested_attributes_for :controls, allow_destroy: true, reject_if: :all_blank
    accepts_nested_attributes_for :control_contexts, allow_destroy: true, reject_if: :all_blank

    scope :by_text, ->(text) { text.blank? ? all : where('lower(name) LIKE :t', t: "%#{text.downcase}%") }
    scope :shared, -> { where(shared: true) }

    def self.policy_class
      ControlListPolicy
    end

    # control_list_run = control_list.build_run user: user, workbench: workbench, referential: target
    #
    # if control_list_run.save
    #   control_list_run.enqueue
    # else
    #   render ...
    # end

    class Run < Operation
      # The Workbench where controls are executed
      self.table_name = 'control_list_runs'

      belongs_to :workbench, optional: false
      delegate :workgroup, to: :workbench

      # The Referential where controls are executed.
      # Optional, because the user can run controls on Stop Areas for example
      belongs_to :referential, optional: true

      # The original control list definition. This control list can have been modified or deleted since.
      # Should only used to provide a link in the UI
      belongs_to :original_control_list,
                 optional: true, foreign_key: :original_control_list_id, class_name: 'Control::List'

      with_options(foreign_key: 'control_list_run_id', dependent: :destroy, inverse_of: :control_list_run) do
        has_many :control_runs, -> { order(position: :asc) }, class_name: 'Control::Base::Run'
        has_many :control_context_runs, class_name: 'Control::Context::Run'
      end
      has_many :control_messages, class_name: 'Control::Message', through: :control_runs

      has_one :processing, as: :processed

      validates :name, presence: true
      validates :original_control_list_id, presence: true, if: :new_record?

      scope :having_status, ->(statuses) { where(user_status: statuses) }

      validates :referential, inclusion: { in: :candidate_referentials }, allow_nil: true

      def candidate_referentials
        [].tap do |candidate_referentials|
          candidate_referentials.concat workbench.referentials.editable
          candidate_referentials.concat workbench.output.referentials
          if workbench.workgroup_owner?
            candidate_referentials.concat workgroup.output.referentials
          end
        end
      end

      def build_with_original_control_list
        return unless original_control_list

        original_control_list.controls.each do |control|
          control_runs << control.build_run
        end

        original_control_list.control_contexts.each do |control_context|
          self.control_context_runs << control_context.build_run
        end
      end

      def final_user_status
        UserStatusFinalizer.new(self).user_status
      end

      class UserStatusFinalizer
        def initialize(control_list_run)
          @control_list_run = control_list_run
        end
        attr_reader :control_list_run

        delegate :control_messages, to: :control_list_run

        def criticities
          # reorder! to avoid problems with default order and pluck
          @criticities ||= control_messages.reorder!.distinct.pluck(:criticity)
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
      end

      def self.policy_class
        ControlListRunPolicy
      end

      def perform
        referential&.switch

        control_runs.each(&:run)
        control_context_runs.each(&:run)
      end
    end
  end
end
