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
             :point_of_interests, :shapes, :connection_links, to: :workbench

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
      Chouette::JourneyPatternsStopPoint.none
    end

    def vehicle_journeys
      Chouette::VehicleJourney.none
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
      Stat::JourneyPatternCoursesByDate.none
    end

    private

    attr_reader :workbench
  end

  class Referential
    def initialize(workbench, referential)
      @workbench = workbench
      @referential = referential
    end

    delegate :lines, :companies, :stop_areas, :routes, :stop_points,
             :journey_patterns, :journey_pattern_stop_points, :vehicle_journeys,
             :time_tables, :time_table_periods, :time_table_dates, :service_counts, to: :referential
    delegate :entrances, :point_of_interests, :shapes, :connection_links, :networks, to: :workbench

    private

    attr_reader :referential, :workbench
  end

  class Owned
    def initialize(scope, workbench)
      @scope = scope
      @workbench = workbench
    end

    delegate :stop_area_providers, :shape_providers, :line_providers,  to: :workbench

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

    delegate :routes, :stop_points, :journey_patterns, :journey_pattern_stop_points, :vehicle_journeys, to: :scope

    private

    attr_accessor :scope, :workbench
  end
end
