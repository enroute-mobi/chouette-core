module Control
  class Base < ApplicationModel
    include OptionsSupport # Check which methods are/should be deprecated

    self.table_name = 'controls'

    belongs_to :control_context, class_name: 'Control::Context', optional: true, inverse_of: :controls # CHOUETTE-3247
    belongs_to :control_list, class_name: 'Control::List', optional: true, inverse_of: :controls # CHOUETTE-3247
    acts_as_list scope: 'control_list_id #{control_list_id ? "= #{control_list_id}" : "IS NULL"} AND control_context_id #{control_context_id ? "= #{control_context_id}" : "IS NULL"}'

    store :options, coder: JSON

    enumerize :criticity, in: %w[warning error], default: 'warning'

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

    def self.short_type
      @short_type ||= self.name.demodulize.underscore
    end

    def workbench
      @workbench ||= (control_list || control_context)&.workbench
    end
    attr_writer :workbench

    delegate :workgroup, to: :workbench, allow_nil: true

    class Run < ApplicationModel
      self.table_name = 'control_runs'

      with_options(inverse_of: :control_runs) do
        belongs_to :control_context_run, class_name: 'Control::Context::Run', optional: true # CHOUETTE-3247
        belongs_to :control_list_run, class_name: 'Control::List::Run', optional: true # CHOUETTE-3247 failing specs
      end

      with_options(foreign_key: 'control_run_id', inverse_of: :control_run) do
        has_many :control_messages, class_name: 'Control::Message', dependent: :delete_all
      end

      store :options, coder: JSON
      # TODO: Retrieve options definition from Conrtol class
      include OptionsSupport

      class << self
        def message_key
          @message_key ||= name.deconstantize.demodulize.underscore.to_sym
        end
      end

      def parent
        control_list_run || control_context_run
      end

      def control_class
        self.class.module_parent
      end

      delegate :message_key, to: :class
      delegate :referential, :workbench, to: :parent, allow_nil: true
      delegate :workgroup, to: :workbench, allow_nil: true

      include AroundMethod
      around_method :run

      def logger
        Rails.logger
      end

      def context
        if control_context_run
          control_context_run
        elsif referential
          LegacyScope::Referential.new(workbench, referential)
        else
          LegacyScope::Owned.new(LegacyScope::Workbench.new(workbench), workbench)
        end
      end

      def messages
        @messages ||= Messages.new(self, Control::Message, :control_run, **messages_options)
      end

      protected

      def around_run(&block)
        logger.tagged "#{self.class}(id:#{id || object_id})" do
          logger.info 'Started'
          Chouette::Benchmark.measure(self.class.to_s, id: id) do
            block.call
          end
          logger.info 'Done'
        end
      end

      def messages_options
        {}
      end

      class Messages < ControlMacro::Messages
        def create(source: nil, **message_attributes)
          super do |message|
            message.error!(criticity: run.criticity, message_key: run.message_key)
            yield message if block_given?
          end
        end
      end
    end
  end
end
