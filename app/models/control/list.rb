module Control
  class List < ApplicationModel
    self.table_name = "control_lists"

    belongs_to :workbench, optional: false
    validates :name, presence: true

    has_many :controls, -> { order(position: :asc) }, class_name: "Control::Base", dependent: :delete_all, foreign_key: "control_list_id", inverse_of: :control_list
    has_many :control_list_runs, class_name: "Control::List::Run", foreign_key: :original_control_list_id
    has_many :control_contexts, class_name: "Control::Context", foreign_key: "control_list_id", inverse_of: :control_list

    accepts_nested_attributes_for :controls, allow_destroy: true, reject_if: :all_blank
    accepts_nested_attributes_for :control_contexts, allow_destroy: true, reject_if: :all_blank

    scope :by_text, ->(text) { text.blank? ? all : where('lower(name) LIKE :t', t: "%#{text.downcase}%") }

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
      self.table_name = "control_list_runs"

      belongs_to :workbench, optional: false
      delegate :workgroup, to: :workbench

      # The Referential where controls are executed.
      # Optional, because the user can run controls on Stop Areas for example
      belongs_to :referential, optional: true

      # The original control list definition. This control list can have been modified or deleted since.
      # Should only used to provide a link in the UI
      belongs_to :original_control_list, optional: true, foreign_key: :original_control_list_id, class_name: 'Control::List'

      has_many :control_runs, -> { order(position: :asc) }, class_name: "Control::Base::Run",
               dependent: :delete_all, foreign_key: "control_list_run_id"

      has_many :control_context_runs, class_name: "Control::Context::Run", dependent: :delete_all, foreign_key: "control_list_run_id", inverse_of: :control_list_run

      validates :name, presence: true
      validates :original_control_list_id, presence: true, if: :new_record?

      has_many :control_messages, class_name: "Control::Message", through: :control_runs

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
          %w{error warning}.find do |criticity|
            criticity.in?(criticities)
          end
        end

        def user_status
          case worst_criticity
          when "error"
            Operation.user_status.failed
          when "warning"
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
        referential.switch if referential

        control_runs.each(&:run)
        control_context_runs.each(&:run)
      end

    end
  end
end
