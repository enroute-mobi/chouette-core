# frozen_string_literal: true

module Import
  # Insert Vehicle Journey and inner models into a Referential (via ReferentialInserter).
  class VehicleJourneyInserter < Inserter
    def insert(vehicle_journey)
      referential_inserter.vehicle_journeys.insert vehicle_journey, before_copy: before_copy
      return unless vehicle_journey.valid?

      vehicle_journey.vehicle_journey_at_stops.each do |vehicle_journey_at_stop|
        vehicle_journey_at_stop.vehicle_journey = vehicle_journey
        referential_inserter.vehicle_journey_at_stops << vehicle_journey_at_stop
      end

      vehicle_journey.vehicle_journey_time_table_relationships.each do |vehicle_journey_time_table|
        vehicle_journey_time_table.vehicle_journey = vehicle_journey
        referential_inserter.vehicle_journey_time_table_relationships << vehicle_journey_time_table
      end

      vehicle_journey.vehicle_journey_footnote_relationships.each do |vehicle_journey_footnote|
        vehicle_journey_footnote.vehicle_journey = vehicle_journey
        referential_inserter.vehicle_journey_footnote_relationships << vehicle_journey_footnote
      end
    end
  end
end
