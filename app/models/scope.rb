# frozen_string_literal: true

# Provides proper models according an initial Scope (like Workbench, Referential, etc)
#
# Used by Controls and Macros to restrict the operated models
module Scope
  class Workbench
    def initialize(workbench)
      @workbench = workbench
    end

    delegate :lines, :companies, :stop_areas, :entrances, :networks,
             :point_of_interests, :shapes, :documents, :connection_links, to: :workbench

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

    def companies
      line_referential.companies.where(id: lines.where.not(company_id: nil).select(:company_id).distinct)
    end

    def networks
      line_referential.networks.where(id: lines.where.not(network_id: nil).select(:network_id).distinct)
    end

    def stop_areas
      stop_area_referential.stop_areas.where(id: stop_points.select(:stop_area_id).distinct)
    end

    def stop_areas_ids
      referential.stop_points.select(:stop_area_id).distinct
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

    def documents
      workgroup.documents.where(id: line_document_memberships.select(:document_id).distinct)
    end

    def line_document_memberships
      workgroup.document_memberships.where(documentable_type: 'Chouette::Line', documentable_id: lines.select(:id))
    end

    def point_of_interests
      PointOfInterest::Base.none
    end

    delegate :routes, :stop_points, :journey_patterns, :journey_pattern_stop_points, :vehicle_journey_at_stops,
             :time_tables, :time_table_periods, :time_table_dates, :service_counts, :vehicle_journeys, to: :referential
    delegate :line_referential, :stop_area_referential, :shape_referential, :workgroup, to: :workbench
    attr_reader :referential, :workbench
  end

  class Owned
    def initialize(scope, workbench)
      @scope = scope
      @workbench = workbench
    end

    delegate :stop_area_providers, :shape_providers, :line_providers, :document_providers, to: :workbench

    def stop_areas
      scope.stop_areas.where(stop_area_provider: stop_area_providers)
    end

    def entrances
      scope.entrances.where(stop_area_provider: stop_area_providers)
    end

    def connection_links
      scope.connection_links.where(stop_area_provider: stop_area_providers)
    end

    def shapes
      scope.shapes.where(shape_provider: shape_providers)
    end

    def documents
      scope.documents.where(document_provider: document_providers)
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

    delegate :routes, :stop_points, :journey_patterns, :journey_pattern_stop_points, :vehicle_journeys, :vehicle_journey_at_stops,
             :time_tables, :time_table_periods, :time_table_dates, :service_counts, to: :scope

    private

    attr_accessor :scope, :workbench
  end
end
