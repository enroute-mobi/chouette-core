# frozen_string_literal: true

module Chouette
  module Planner
    def self.create(from, to, **attributes)
      Chouette::Planner::Base.new(from: from, to: to, **attributes).tap do |planner|
        yield planner if block_given?
      end
    end

    def self.default(context:, from:, to:)
      create(from, to, origin_time_of_day: TimeOfDay.parse('15:00')) do |planner|
        planner.extenders << Extender::WalkableStopAreas.new(context.stop_areas)
        planner.extenders << Extender::ByVehicleJourneyStopAreas.new(
          vehicle_journeys: context.vehicle_journeys,
          time_tables: context.time_tables,
          maximum_time_of_day: TimeOfDay.parse('18:00')
        )

        to = Step.for(to) # Geo::Position.from doesn't support String parsing
        planner.evaluator = Evaluator::Add.new(Evaluator::RemainingDuration.new(with: to.position),
                                               Evaluator::Duration.new)
      end
    end
  end
end
