# frozen_string_literal: true

module Macro
  class Base < ApplicationModel
    include OptionsSupport # Check which methods are/should be deprecated

    self.table_name = 'macros'

    belongs_to :macro_context, class_name: 'Macro::Context', optional: true, inverse_of: :macros
    belongs_to :macro_list, class_name: 'Macro::List', optional: true, inverse_of: :macros
    acts_as_list scope: 'macro_list_id #{macro_list_id ? "= #{macro_list_id}" : "IS NULL"} AND macro_context_id #{macro_context_id ? "= #{macro_context_id}" : "IS NULL"}' # rubocop:disable Lint/InterpolationCheck

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

    def self.short_type
      @short_type ||= name.demodulize.underscore
    end

    def run_class
      @run_class ||= self.class.const_get('Run')
    end

    class Run < ApplicationModel
      self.table_name = 'macro_runs'

      belongs_to :macro_context_run, class_name: 'Macro::Context::Run', optional: true, inverse_of: :macro_runs
      belongs_to :macro_list_run, class_name: 'Macro::List::Run', inverse_of: :macro_runs

      has_many :macro_messages, class_name: 'Macro::Message', foreign_key: 'macro_run_id', inverse_of: :macro_run

      store :options, coder: JSON
      # TODO: Retrieve options definition from Macro class
      include OptionsSupport

      def parent
        macro_list_run || macro_context_run
      end

      def control_class
        self.class.parent
      end

      delegate :referential, :workbench, to: :parent, allow_nil: true
      delegate :workgroup, to: :workbench

      include AroundMethod
      around_method :run

      def logger
        Rails.logger
      end

      def scope
        parent&.scope
      end

      class CustomScope
        def initialize(macro_run)
          @macro_run = macro_run
        end
        attr_accessor :macro_run

        def contexts
          # TODO: Support nested contexts
          # For the moment only a single Macro::Context:Run can be defined
          @contexts ||= [macro_run.macro_context_run].compact
        end

        def scope(initial_scope)
          contexts.inject(initial_scope) do |scope, context|
            context.scope(scope)
          end
        end
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
    end
  end
end

# STI
require_dependency 'macro/associate_shape'
require_dependency 'macro/associate_stop_area_referent'
require_dependency 'macro/compute_journey_pattern_distances'
require_dependency 'macro/compute_journey_pattern_durations'
require_dependency 'macro/create_code'
require_dependency 'macro/create_shape'
require_dependency 'macro/create_stop_area_referents'
require_dependency 'macro/define_attribute_from_particulars'
require_dependency 'macro/define_postal_address'
require_dependency 'macro/dummy'
require_dependency 'macro/update_stop_area_compass_bearing'
require_dependency 'macro/compute_service_counts'
require_dependency 'macro/associate_documents'
require_dependency 'macro/create_code_from_sequence'
