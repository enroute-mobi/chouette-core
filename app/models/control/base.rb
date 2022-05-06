module Control
  class Base < ApplicationModel
    include OptionsSupport # Check which methods are/should be deprecated

    self.table_name = "controls"

    belongs_to :control_context, class_name: "Control::Context", optional: true, inverse_of: :controls
    belongs_to :control_list, class_name: "Control::List", optional: true, inverse_of: :controls
    acts_as_list scope: 'control_list_id #{control_list_id ? "= #{control_list_id}" : "IS NULL"} AND control_context_id #{control_context_id ? "= #{control_context_id}" : "IS NULL"}'

    store :options, coder: JSON

		enumerize :criticity, in: %w(warning error), default: "warning"

    def build_run
      run_attributes = {
        name: name,
        criticity: criticity,
        code: code,
        comments: comments,
        position: position,
        options: options
      }
      run_class.new run_attributes
    end

    def run_class
      @run_class ||= self.class.const_get("Run")
    end

    def workbench
      (control_list || control_context).workbench
    end

    delegate :workgroup, to: :workbench

    class Run < ApplicationModel
      self.table_name = "control_runs"

      belongs_to :control_context_run, class_name: "Control::Context::Run", optional: true, inverse_of: :control_runs
      belongs_to :control_list_run, class_name: "Control::List::Run", inverse_of: :control_runs

      has_many :control_messages, class_name: "Control::Message", foreign_key: "control_run_id", inverse_of: :control_run

      store :options, coder: JSON
      # TODO Retrieve options definition from Conrtol class
      include OptionsSupport

      def parent
        control_list_run || control_context_run
      end

      delegate :referential, :workbench, to: :parent, allow_nil: true
      delegate :workgroup, to: :workbench

      # TODO Share this mechanism
      def self.method_added(method_name)
        unless @setting_callback || method_name != :run
          @setting_callback = true
          original = instance_method :run
          define_method :protected_run do |*args, &block|
            around_run do
              original.bind(self).call(*args, &block)
            end
          end
          alias_method :run, :protected_run
          @setting_callback = false
        end

        super method_name
      end

      def logger
        Rails.logger
      end

      def context
        control_context_run || referential || workbench
      end

      protected

      def around_run(&block)
        logger.tagged "#{self.class.to_s}(id:#{id||object_id})" do
          logger.info "Started"
          Chouette::Benchmark.measure(self.class.to_s, id: id) do
            block.call
          end
          logger.info "Done"
        end
      end
    end
  end
end
