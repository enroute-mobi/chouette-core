# frozen_string_literal: true

module Macro
  class Context < ApplicationModel
    include OptionsSupport # Check which methods are/should be deprecated

    self.table_name = 'macro_contexts'

    belongs_to :macro_list, class_name: 'Macro::List', optional: false, inverse_of: :macro_contexts

    def workbench
      @workbench || macro_list&.workbench
    end
    attr_writer :workbench

    has_many :macros, -> { order(position: :asc) },
             class_name: 'Macro::Base', dependent: :delete_all,
             foreign_key: 'macro_context_id', inverse_of: :macro_context

    has_many :macro_context_runs, class_name: 'Macro::Context::Run', foreign_key: 'macro_context_id',
                                  inverse_of: :macro_context, dependent: nil

    store :options, coder: JSON

    accepts_nested_attributes_for :macros, allow_destroy: true, reject_if: :all_blank

    def self.available
      [
        Macro::Context::TransportMode,
        Macro::Context::SavedSearch
      ]
    end

    def build_run
      run_attributes = {
        name: name,
        options: options,
        comments: comments
      }
      context_runs = run_class.new run_attributes
      macros.each do |macro|
        context_runs.macro_runs << macro.build_run
      end
      context_runs
    end

    def run_class
      @run_class ||= self.class.const_get('Run')
    end

    class Run < ApplicationModel
      self.table_name = 'macro_context_runs'

      belongs_to :macro_list_run, class_name: 'Macro::List::Run', optional: false, inverse_of: :macro_context_runs
      belongs_to :macro_context, class_name: 'Macro::Context', optional: true, inverse_of: :macro_context_runs

      has_many :macro_runs, -> { order(position: :asc) },
               class_name: 'Macro::Base::Run', foreign_key: 'macro_context_run_id',
               inverse_of: :macro_context_run, dependent: :delete_all

      has_many :macro_messages, class_name: 'Macro::Message', through: :macro_runs

      store :options, coder: JSON

      delegate :referential, :workbench, to: :macro_list_run

      def parent
        macro_list_run
        # TODO: Nested context should change this method into
        # macro_context_run || macro_list_run
      end

      def scope(initial_scope = parent.scope)
        initial_scope
      end

      def run
        logger.tagged "#{self.class}(id:#{id || object_id})" do
          macro_runs.each(&:run)
        end
      end
    end
  end
end

# STI
require_dependency 'macro/context/transport_mode'
