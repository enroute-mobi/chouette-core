module Macro
  class Base < ApplicationModel
    include OptionsSupport # Check which methods are/should be deprecated

    self.table_name = "macros"

    belongs_to :macro_context, class_name: "Macro::Context", optional: true, inverse_of: :macros
    belongs_to :macro_list, class_name: "Macro::List", optional: true, inverse_of: :macros
    acts_as_list scope: 'macro_list_id #{macro_list_id ? "= #{macro_list_id}" : "IS NULL"} AND macro_context_id #{macro_context_id ? "= #{macro_context_id}" : "IS NULL"}'

    store :options, coder: JSON

    def build_run
      run_attributes = {
        name: name,
        comments: comments,
        position: position,
        options: options
      }
      run_class.new run_attributes
    end

    def run_class
      @run_class ||= self.class.const_get("Run")
    end

    class Run < ApplicationModel
      self.table_name = "macro_runs"

      belongs_to :macro_context_run, class_name: "Macro::Context::Run", optional: true, inverse_of: :macro_runs
      belongs_to :macro_list_run, class_name: "Macro::List::Run", inverse_of: :macro_runs

      has_many :macro_messages, class_name: "Macro::Message", foreign_key: "macro_run_id", inverse_of: :macro_run

      store :options, coder: JSON
      # TODO Retrieve options definition from Macro class
      include OptionsSupport

      def parent
        macro_list_run || macro_context_run
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
        macro_context_run || referential || workbench
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

# STI
require_dependency 'macro/associate_shape'
require_dependency 'macro/create_code'
require_dependency 'macro/dummy'
require_dependency 'macro/update_stop_area_compass_bearing'
