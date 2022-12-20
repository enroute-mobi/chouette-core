module Macro
  class List < ApplicationModel
    self.table_name = "macro_lists"

    belongs_to :workbench, optional: false
    validates :name, presence: true

    has_many :macros, -> { order(position: :asc) }, class_name: "Macro::Base", dependent: :delete_all, foreign_key: "macro_list_id", inverse_of: :macro_list
    has_many :macro_list_runs, class_name: "Macro::List::Run", foreign_key: :original_macro_list_id
    has_many :macro_contexts, class_name: "Macro::Context", foreign_key: "macro_list_id", inverse_of: :macro_list

    accepts_nested_attributes_for :macros, allow_destroy: true, reject_if: :all_blank
    accepts_nested_attributes_for :macro_contexts, allow_destroy: true, reject_if: :all_blank

    scope :by_text, ->(text) { text.blank? ? all : where('lower(name) LIKE :t', t: "%#{text.downcase}%") }

    def self.policy_class
      MacroListPolicy
    end

    # macro_list_run = macro_list.build_run user: user, workbench: workbench, referential: target
    #
    # if macro_list_run.save
    #   macro_list_run.enqueue
    # else
    #   render ...
    # end

    class Run < Operation
      # The Workbench where macros are executed
      self.table_name = "macro_list_runs"

      belongs_to :workbench, optional: false
      delegate :workgroup, to: :workbench

      # The Referential where macros are executed.
      # Optional, because the user can run macros on Stop Areas for example
      belongs_to :referential, optional: true

      # The original macro list definition. This macro list can have been modified or deleted since.
      # Should only used to provide a link in the UI
      belongs_to :original_macro_list, optional: true, foreign_key: :original_macro_list_id, class_name: 'Macro::List'

      has_many :macro_runs, -> { order(position: :asc) }, class_name: "Macro::Base::Run",
               dependent: :delete_all, foreign_key: "macro_list_run_id"

      has_many :macro_context_runs, class_name: "Macro::Context::Run", dependent: :delete_all, foreign_key: "macro_list_run_id", inverse_of: :macro_list_run

      has_one :processing, as: :processed

      validates :name, presence: true
      validates :original_macro_list_id, presence: true, if: :new_record?

      scope :having_status, ->(statuses) { where(status: statuses) }

      def build_with_original_macro_list
        return unless original_macro_list

        original_macro_list.macros.each do |macro|
          macro_runs << macro.build_run
        end

        original_macro_list.macro_contexts.each do |macro_context|
          self.macro_context_runs << macro_context.build_run
        end

        self.workbench = original_macro_list.workbench
      end

      def self.policy_class
        MacroListRunPolicy
      end

      def perform
        referential.switch if referential

        macro_runs.each(&:run)
        macro_context_runs.each(&:run)
      end

      def base_scope
        if referential
          ReferentialScope.new(workbench, referential)
        else
          WorkbenchScope.new(workbench)
        end
      end

      def owned_scope
        OwnerScope.new(base_scope, workbench)
      end

      def scope
        owned_scope
      end

      class WorkbenchScope
        def initialize(workbench)
          @workbench = workbench
        end
        attr_reader :workbench

        delegate :lines, :companies, :stop_areas, :entrances, :point_of_interests, :shapes, to: :workbench

        def routes
          Chouette::Route.none
        end

        def stop_points
          Chouette::StopPoint.none
        end

        def journey_patterns
          Chouette::JourneyPattern.none
        end

        def vehicle_journeys
          Chouette::VehicleJourney.none
        end
      end

      class ReferentialScope
        def initialize(workbench, referential)
          @workbench = workbench
          @referential = referential
        end
        attr_reader :referential, :workbench

        delegate :lines, :companies, :stop_areas, :routes, :stop_points, :journey_patterns, :vehicle_journeys,
                 to: :referential
        delegate :entrances, :point_of_interests, :shapes, to: :workbench
      end

      class OwnerScope
        def initialize(scope, workbench)
          @scope = scope
          @workbench = workbench
        end
        attr_accessor :scope, :workbench

        delegate :stop_area_providers, :shape_providers, :line_providers, to: :workbench

        def stop_areas
          scope.stop_areas.where(stop_area_provider: stop_area_providers)
        end

        def entrances
          scope.entrances.where(stop_area_provider: stop_area_providers)
        end

        def shapes
          scope.shapes.where(shape_provider: shape_providers)
        end

        def point_of_interests
          scope.point_of_interests.where(shape_provider: shape_providers)
        end

        def lines
          scope.lines.where(line_provider: line_providers)
        end

        def networks
          scope.networks.where(line_provider: line_providers)
        end

        def companies
          scope.companies.where(line_provider: line_providers)
        end

        def journey_patterns
          scope.journey_patterns
        end

        def vehicle_journeys
          scope.vehicle_journeys
        end

        def routes
          scope.routes
        end

        def stop_points
          scope.stop_points
        end
      end

    end
  end
end
