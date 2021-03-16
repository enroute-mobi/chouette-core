# Selects which models need to be included into an Export
module Export::Scope
  def self.build referential_id, date_range: nil, line_ids: []
    raise "lines ids cannot be empty" if line_ids.empty?

    Builder.new(
      Referential.find(referential_id),
      date_range,
      line_ids
    ).scope
  end

  class Builder
    attr_reader :default_scope, :date_range
    def initialize(referential, date_range, line_ids)
      @default_scope = All.new(referential)
      @date_range = date_range
      @lines_ids = line_ids
    end

    def period_scope
      date_range ? DateRange.new(date_range) : Scheduled.new
    end

    def line_scope
      Lines.new(@line_ids)
    end

    def inner_scopes
      [period_scope, line_scope]
    end

    def scope
      inner_scopes.reduce(default_scope) do |scope, inner_scope|
        inner_scope.apply_current_scope(scope)
      end
    end
  end

  module Base
    delegate :workgroup, :workbench, :line_referential, :stop_area_referential, :metadatas, to: :referential
    delegate :shape_referential, to: :workgroup

    delegate :companies, to: :line_referential

    delegate :shapes, to: :shape_referential

    delegate :codes, to: :workgroup

    def organisations
      workgroup.organisations.where(id: metadatas.joins(referential_source: :organisation).distinct.pluck('organisations.id'))
    end
  end

  class All
    include Base

    attr_reader :referential

    def initialize(referential)
      @referential = referential
    end

    delegate :vehicle_journeys, :vehicle_journey_at_stops, :journey_patterns, :routes, :stop_points, :time_tables, :referential_codes, to: :referential

    def stop_areas
      (workbench || stop_area_referential).stop_areas
    end

    def lines
      (workbench || line_referential).lines
    end
  end

  module Filterable
    include Base

    attr_reader :current_scope

    delegate :referential, to: :current_scope

    def apply_current_scope(current_scope)
      @current_scope = current_scope
      self
    end

    def vehicle_journeys
      raise 'not yet implemented'
    end

    def lines
      current_scope.lines.distinct.joins(routes: :vehicle_journeys)
        .where("vehicle_journeys.id" => vehicle_journeys)
    end

    def time_tables
      current_scope.time_tables.joins(:vehicle_journeys).where("vehicle_journeys.id" => vehicle_journeys).distinct
    end

    def vehicle_journey_at_stops
      current_scope.vehicle_journey_at_stops.where(vehicle_journey: vehicle_journeys)
    end

    def routes
      current_scope.routes.joins(:vehicle_journeys).distinct
        .where("vehicle_journeys.id" => vehicle_journeys)
    end

    def journey_patterns
      current_scope.journey_patterns.joins(:vehicle_journeys).distinct
        .where("vehicle_journeys.id" => vehicle_journeys)
    end

    def shapes
      current_scope.shapes.where(id: journey_patterns.select(:shape_id))
    end

    def stop_points
      current_scope.stop_points.distinct.joins(route: :vehicle_journeys)
        .where("vehicle_journeys.id" => vehicle_journeys)
    end

    def stop_areas
      stop_areas_in_routes =
        current_scope.stop_areas.joins(routes: :vehicle_journeys).distinct
          .where("vehicle_journeys.id" => vehicle_journeys)

      stop_areas_in_specific_vehicle_journey_at_stops =
        current_scope.stop_areas.joins(:specific_vehicle_journey_at_stops).distinct
          .where("vehicle_journey_at_stops.vehicle_journey_id" => vehicle_journeys)

      Chouette::StopArea.union(stop_areas_in_routes, stop_areas_in_specific_vehicle_journey_at_stops)
    end
  end

  # Selects VehicleJourneys in a Date range, and all other models if they are required
  # to describe these VehicleJourneys
  class DateRange
    include Filterable

    attr_reader :date_range

    def initialize(date_range)
      @date_range = date_range
    end

    def vehicle_journeys
      current_scope.vehicle_journeys.with_matching_timetable(date_range)
    end

    def time_tables
      current_scope.time_tables.overlapping(date_range)
    end

    def metadatas
      current_scope.metadatas.include_daterange(date_range)
    end
  end

  class Scheduled
    include Filterable

    def vehicle_journeys
      current_scope.vehicle_journeys.scheduled
    end
  end

  class Lines
    include Filterable

    attr_reader 

    def initialize(selected_line_ids)
      @line_ids_proc = ->(current_scope) { current_scope.lines.where(id: selected_line_ids).pluck(:id) }
    end

    def selected_line_ids
      @line_ids_proc.call(current_scope)
    end

    def vehicle_journeys
      current_scope.vehicle_journeys.with_lines(selected_line_ids)
    end

    def metadatas
      current_scope.metadatas.include_lines(selected_line_ids)
    end
  end
end
