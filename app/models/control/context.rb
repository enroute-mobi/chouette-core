module Control
  class Context < ApplicationModel
    include OptionsSupport

    self.table_name = 'control_contexts'

    belongs_to :control_list, class_name: 'Control::List', optional: false, inverse_of: :control_contexts

    with_options(inverse_of: :control_context, foreign_key: 'control_context_id') do
      has_many :controls, -> { order(position: :asc) }, class_name: 'Control::Base', dependent: :delete_all
      has_many :control_context_runs, class_name: 'Control::Context::Run'
    end

    store :options, coder: JSON

    accepts_nested_attributes_for :controls, allow_destroy: true, reject_if: :all_blank

    delegate :workbench, to: :control_list

    def self.available
      [
        Control::Context::TransportMode,
        Control::Context::OperatingPeriod,
        Control::Context::Lines
      ]
    end

    def build_run
      run_attributes = {
        name: name,
        options: options,
        comments: comments
      }
      context_runs = run_class.new run_attributes
      controls.each do |control|
        context_runs.control_runs << control.build_run
      end
      context_runs
    end

    def run_class
      @run_class ||= self.class.const_get('Run')
    end

    class Run < ApplicationModel
      include OptionsSupport

      self.table_name = 'control_context_runs'

      with_options(inverse_of: :control_context_runs) do
        belongs_to :control_list_run, class_name: 'Control::List::Run', optional: false
        belongs_to :control_context, class_name: 'Control::Context', optional: true
      end

      with_options(inverse_of: :control_context_run, foreign_key: 'control_context_run_id') do
        has_many :control_runs, -> { order(position: :asc) }, class_name: 'Control::Base::Run', dependent: :destroy
      end

      store :options, coder: JSON

      delegate :referential, :workbench, to: :control_list_run

      def context
        referential || Scope::Workbench.new(workbench)
      end

      def run
        logger.tagged "#{self.class}(id:#{id || object_id})" do
          control_runs.each(&:run)
        end
      end
    end
  end
end
