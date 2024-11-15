# frozen_string_literal: true

# Provides proper models according an initial Scope (like Workbench, Referential, etc)
#
# Used by Controls and Macros to restrict the operated models
module Scope
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

  class Referential
    def initialize(workbench, referential)
      @workbench = workbench
      @referential = referential
    end

    def lines
      referential.metadatas_lines
    end

    def line_groups
      line_referential.line_groups.where(
        id: ::LineGroup::Member.where(line_id: lines.select(:id)).select(:group_id).distinct
      )
    end

    def line_notices
      line_referential.line_notices.where(
        id: ::Chouette::LineNoticeMembership.where(line_id: lines.select(:id)).select(:line_notice_id).distinct
      )
    end

    def companies
      line_referential.companies.where(id: lines.where.not(company_id: nil).select(:company_id).distinct)
    end

    def networks
      line_referential.networks.where(id: lines.where.not(network_id: nil).select(:network_id).distinct)
    end

    def stop_areas
      stop_area_referential.stop_areas.where(id: stop_points.select(:stop_area_id).distinct)
    end

    def stop_area_groups
      stop_area_referential.stop_area_groups.where(
        id: ::StopAreaGroup::Member.where(stop_area_id: stop_areas.select(:id)).select(:group_id).distinct
      )
    end

    def entrances
      stop_area_referential.entrances.where(stop_area_id: stop_areas_ids)
    end

    def connection_links
      stop_area_referential.connection_links.where(departure_id: stop_areas_ids, arrival_id: stop_areas_ids)
    end

    def shapes
      shape_referential.shapes.where(id: journey_patterns.where.not(shape_id: nil).select(:shape_id).distinct)
    end

    def point_of_interests
      PointOfInterest::Base.none
    end

    def service_facility_sets
      shape_referential.service_facility_sets.where(id: vehicle_journeys.select('UNNEST(service_facility_set_ids)'))
    end

    def accessibility_assessments
      ::AccessibilityAssessment.none
    end

    def fare_zones
      fare_referential.fare_zones.where(
        id: ::Fare::StopAreaZone.where(stop_area_id: stop_areas.select(:id)).select(:fare_zone_id).distinct
      )
    end

    def line_routing_constraint_zones
      line_referential.line_routing_constraint_zones.where(
        'line_ids && (?) OR stop_area_ids && (?)',
        lines.select('ARRAY_AGG(lines.id)'),
        stop_areas.select('ARRAY_AGG(stop_areas.id)')
      )
    end

    def documents
      workgroup.documents.where(
        id: line_document_memberships.or(stop_area_document_memberships)
                                     .or(company_document_memberships)
                                     .select(:document_id)
                                     .distinct
      )
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
    delegate :line_referential,
             :stop_area_referential,
             :shape_referential,
             :fare_referential,
             :workgroup,
             to: :workbench
    attr_reader :referential, :workbench

    private

    def stop_areas_ids
      referential.stop_points.select(:stop_area_id).distinct
    end

    def line_document_memberships
      workgroup.document_memberships.where(
        documentable_type: 'Chouette::Line',
        documentable_id: lines.select(:id)
      )
    end

    def stop_area_document_memberships
      workgroup.document_memberships.where(
        documentable_type: 'Chouette::StopArea',
        documentable_id: stop_areas_ids
      )
    end

    def company_document_memberships
      workgroup.document_memberships.where(
        documentable_type: 'Chouette::Company',
        documentable_id: companies.select(:id)
      )
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
             to: :scope

    private

    attr_accessor :scope, :workbench
  end
end
