# Selects which models need to be included into an Export
module Export::Scope

  class Base

    attr_reader :referential

    def initialize(referential)
      @referential = referential
    end

    delegate :workbench, to: :referential

    delegate :vehicle_journeys, :journey_patterns, :routes, :time_tables, to: :referential
    delegate :stop_areas, to: :workbench
    delegate :lines, :companies, to: :workbench

  end

  class All < Base

  end

  # Selects VehicleJourneys in a Date range, and all other models if they are required
  # to describe these VehicleJourneys
  class DateRange < Base

    attr_reader :date_range

    def initialize(referential, date_range)
      super referential
      @date_range = date_range
    end

    def vehicle_journeys
      @vehicle_journeys ||= super.with_matching_timetable(date_range)
    end

    def lines
      super.joins(routes: :vehicle_journeys).where("vehicle_journeys.id" => vehicle_journeys)
    end

    # TODO

  end

end
