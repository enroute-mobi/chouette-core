# frozen_string_literal: true

# Provides proper models according an initial Scope (like Workbench, Referential, etc)
#
# Used by Controls and Macros to restrict the operated models
module Scope
  class CenteredOnModel
    class_attribute :links, instance_accessor: false, default: {}

    class << self
      def link(source, target, &block)
        mod = Module.new
        mod.define_method(target, &block)

        links[source] ||= {}
        links[source][target] = mod
      end

      def scope_centered_on(model) # rubocop:disable Metrics/MethodLength
        included_models = Set.new
        included_models << model

        queue = [model]
        while queue.any?
          source = queue.pop
          next unless links.key?(source)

          links[source].each do |target, mod|
            next if target.in?(included_models)

            include mod
            included_models << target
            queue << target
          end
        end
      end
    end

    link :routes, :lines do
      line_referential_scope.lines.joins(:routes).where(routes: { id: route_ids }).distinct
    end
    link :lines, :routes do
      referential_scope.routes.where(line_id: line_ids)
    end
    link :lines, :line_groups do
      line_referential_scope.line_groups.where(
        id: ::LineGroup::Member.where(line_id: line_ids).select(:group_id).distinct
      )
    end
    link :lines, :line_notices do
      line_referential_scope.line_notices.where(
        id: ::Chouette::LineNoticeMembership.where(line_id: line_ids).select(:line_notice_id).distinct
      )
    end
    link :lines, :companies do
      line_referential_scope.companies.where(id: lines.where.not(company_id: nil).select(:company_id).distinct)
    end
    link :lines, :networks do
      line_referential_scope.networks.where(id: lines.where.not(network_id: nil).select(:network_id).distinct)
    end
    link :routes, :shapes do
      shape_referential_scope.shapes.where(id: journey_patterns.where.not(shape_id: nil).select(:shape_id).distinct)
    end
    link :routes, :stop_points do
      referential_scope.stop_points.where(route_id: route_ids)
    end
    link :stop_points, :routes do
      referential_scope.routes.joins(:stop_points).where(stop_points: stop_points).distinct
    end
    link :stop_points, :stop_areas do
      stop_area_referential_scope.stop_areas.where(id: stop_points.select(:stop_area_id).distinct)
    end
    link :stop_areas, :stop_points do
      referential_scope.stop_points.where(stop_area_id: stop_area_ids)
    end
    link :stop_areas, :stop_area_groups do
      stop_area_referential_scope.stop_area_groups.where(
        id: ::StopAreaGroup::Member.where(stop_area_id: stop_area_ids).select(:group_id).distinct
      )
    end
    link :stop_areas, :entrances do
      stop_area_referential_scope.entrances.where(stop_area_id: stop_area_ids)
    end
    link :stop_areas, :connection_links do
      stop_area_referential_scope.connection_links.where(departure_id: stop_area_ids, arrival_id: stop_area_ids)
    end
    link :stop_areas, :fare_zones do
      fare_referential_scope.fare_zones.where(
        id: ::Fare::StopAreaZone.where(stop_area_id: stop_area_ids).select(:fare_zone_id).distinct
      )
    end
    link :routes, :journey_patterns do
      referential_scope.journey_patterns.where(route_id: route_ids)
    end
    link :journey_patterns, :vehicle_journeys do
      referential_scope.vehicle_journeys.where(journey_pattern_id: journey_pattern_ids)
    end
    link :vehicle_journeys, :service_facility_sets do
      shape_referential_scope.service_facility_sets.where(
        id: vehicle_journeys.select('UNNEST(service_facility_set_ids)')
      )
    end
    link :vehicle_journeys, :time_tables do
      referential_scope.time_tables.joins(:vehicle_journeys).where(
        vehicle_journeys: { id: vehicle_journeys.select(:id) }
      )
    end
    link :lines, :service_counts do
      referential_scope.service_counts.where(line_id: line_ids)
    end

    def point_of_interests
      ::PointOfInterest::Base.none
    end

    def accessibility_assessments
      ::AccessibilityAssessment.none
    end

    def line_routing_constraint_zones
      line_referential_scope.line_routing_constraint_zones.where(
        'line_ids && (?) OR stop_area_ids && (?)',
        lines.select('ARRAY_AGG(lines.id)'),
        stop_areas.select('ARRAY_AGG(stop_areas.id)')
      )
    end

    def documents
      workgroup_scope.documents.where(
        id: line_document_memberships.or(stop_area_document_memberships)
                                     .or(company_document_memberships)
                                     .select(:document_id)
                                     .distinct
      )
    end

    def contracts
      workgroup_scope.contracts.where(company_id: company_ids).or(
        workgroup_scope.contracts.where('line_ids && (?)', lines.select('ARRAY_AGG(lines.id)'))
      )
    end

    protected

    def workgroup_scope
      raise NotImplementedError
    end

    def line_referential_scope
      raise NotImplementedError
    end

    def stop_area_referential_scope
      raise NotImplementedError
    end

    def shape_referential_scope
      raise NotImplementedError
    end

    def fare_referential_scope
      raise NotImplementedError
    end

    def referential_scope
      raise NotImplementedError
    end

    private

    def line_ids
      lines.select(:id)
    end

    def company_ids
      companies.select(:id)
    end

    def stop_area_ids
      stop_areas.select(:id)
    end

    def route_ids
      routes.select(:id)
    end

    def journey_pattern_ids
      journey_patterns.select(:id)
    end

    def line_document_memberships
      workgroup_scope.document_memberships.where(
        documentable_type: 'Chouette::Line',
        documentable_id: line_ids
      )
    end

    def stop_area_document_memberships
      workgroup_scope.document_memberships.where(
        documentable_type: 'Chouette::StopArea',
        documentable_id: stop_area_ids
      )
    end

    def company_document_memberships
      workgroup_scope.document_memberships.where(
        documentable_type: 'Chouette::Company',
        documentable_id: company_ids
      )
    end
  end

  class Workbench
    def initialize(workbench)
      @workbench = workbench
    end

    delegate :lines,
             :line_groups,
             :line_notices,
             :companies,
             :networks,
             :stop_areas,
             :stop_area_groups,
             :entrances,
             :connection_links,
             :shapes,
             :point_of_interests,
             :service_facility_sets,
             :accessibility_assessments,
             :fare_zones,
             :line_routing_constraint_zones,
             :document_memberships,
             :documents,
             :contracts,
             :workgroup,
             to: :workbench

    def routes
      Chouette::Route.none
    end

    def stop_points
      Chouette::StopPoint.none
    end

    def journey_patterns
      Chouette::JourneyPattern.none
    end

    def journey_pattern_stop_points
      Chouette::JourneyPatternStopPoint.none
    end

    def vehicle_journeys
      Chouette::VehicleJourney.none
    end

    def vehicle_journey_at_stops
      Chouette::VehicleJourneyAtStop.none
    end

    def time_tables
      Chouette::TimeTable.none
    end

    def time_table_periods
      Chouette::TimeTablePeriod.none
    end

    def time_table_dates
      Chouette::TimeTableDate.none
    end

    def service_counts
      ServiceCount.none
    end

    private

    attr_reader :workbench
  end

  class Referential < CenteredOnModel
    def initialize(workbench, referential)
      super()
      @workbench = workbench
      @referential = referential
    end
    attr_reader :workbench, :referential

    scope_centered_on :lines

    def lines
      referential.metadatas_lines
    end

    delegate :routes,
             :stop_points,
             :journey_patterns,
             :journey_pattern_stop_points,
             :vehicle_journeys,
             :vehicle_journey_at_stops,
             :time_tables,
             :time_table_periods,
             :time_table_dates,
             :service_counts,
             to: :referential
    delegate :workgroup, to: :workbench

    protected

    def workgroup_scope
      workbench.workgroup
    end

    def line_referential_scope
      workbench.line_referential
    end

    def stop_area_referential_scope
      workbench.stop_area_referential
    end

    def shape_referential_scope
      workbench.shape_referential
    end

    def fare_referential_scope
      workbench.fare_referential
    end

    def referential_scope
      referential
    end

    private

    def stop_areas_ids
      referential.stop_points.select(:stop_area_id).distinct
    end
  end

  class Owned
    def initialize(scope, workbench)
      @scope = scope
      @workbench = workbench
    end

    delegate :line_providers,
             :stop_area_providers,
             :shape_providers,
             :fare_providers,
             :document_providers,
             :workgroup,
             to: :workbench

    %w[
      lines
      line_groups
      line_notices
      companies
      networks
      line_routing_constraint_zones
    ].each do |method_name|
      class_eval <<-RUBY, __FILE__, __LINE__ + 1
        def #{method_name}
          scope.#{method_name}.where(line_provider: line_providers)
        end
      RUBY
    end

    %w[
      stop_areas
      stop_area_groups
      entrances
      connection_links
    ].each do |method_name|
      class_eval <<-RUBY, __FILE__, __LINE__ + 1
        def #{method_name}
          scope.#{method_name}.where(stop_area_provider: stop_area_providers)
        end
      RUBY
    end

    %w[
      shapes
      point_of_interests
      service_facility_sets
      accessibility_assessments
    ].each do |method_name|
      class_eval <<-RUBY, __FILE__, __LINE__ + 1
        def #{method_name}
          scope.#{method_name}.where(shape_provider: shape_providers)
        end
      RUBY
    end

    def fare_zones
      scope.fare_zones.where(fare_provider: fare_providers)
    end

    def documents
      scope.documents.where(document_provider: document_providers)
    end

    delegate :contracts,
             :routes,
             :stop_points,
             :journey_patterns,
             :journey_pattern_stop_points,
             :vehicle_journeys,
             :vehicle_journey_at_stops,
             :time_tables,
             :time_table_periods,
             :time_table_dates,
             :service_counts,
             to: :scope

    private

    attr_accessor :scope, :workbench
  end

  class Search < ::Scope::CenteredOnModel
    class << self
      def search_on(model)
        scope_centered_on(model)

        class_eval <<-RUBY, __FILE__, __LINE__ + 1
          def #{model}
            search.without_pagination.search(initial_scope.#{model})
          end
        RUBY
      end
    end

    def initialize(initial_scope, search)
      super()
      @initial_scope = initial_scope
      @search = search
    end
    attr_reader :initial_scope, :search

    delegate :point_of_interests,
             :accessibility_assessments,
             to: :initial_scope

    protected

    def workgroup_scope
      initial_scope.workgroup
    end

    alias line_referential_scope initial_scope
    alias stop_area_referential_scope initial_scope
    alias shape_referential_scope initial_scope
    alias fare_referential_scope initial_scope
    alias referential_scope initial_scope
  end
end
