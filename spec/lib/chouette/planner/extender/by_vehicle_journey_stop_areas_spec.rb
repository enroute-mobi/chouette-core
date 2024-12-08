# frozen_string_literal: true

RSpec.describe Chouette::Planner::Extender::ByVehicleJourneyStopAreas do
  subject(:extender) { described_class.new vehicle_journeys: vehicle_journeys, time_tables: time_tables }

  let(:context) do
    Chouette.create do
      time_table :first
      vehicle_journey time_tables: [:first]
    end
  end

  let(:vehicle_journey) { context.vehicle_journey }
  let(:vehicle_journeys) { Chouette::VehicleJourney.where(id: vehicle_journey) }

  let(:time_table) { context.time_table(:first) }
  let(:time_tables) { Chouette::TimeTable.where(id: time_table)  }

  before { context.referential.switch }

  describe '#extend' do
    let(:departure_vehicle_journey_at_stop) { vehicle_journey.vehicle_journey_at_stops.first }
    let(:departure_stop_area) { departure_vehicle_journey_at_stop.stop_point.stop_area }
    let(:departure_time_of_day) { departure_vehicle_journey_at_stop.departure_time_of_day + -1.minute }

    let(:last_step) { Chouette::Planner::Step.for(departure_stop_area) }
    let(:journey) { Chouette::Planner::Journey.new(step: last_step, origin_time_of_day: departure_time_of_day) }

    subject(:extended_journeys) { extender.extend [journey] }

    it { should have_attributes(size: 2) }

    let(:last_stop_area) { vehicle_journey.vehicle_journey_at_stops.last.stop_point.stop_area }

    it {
      is_expected.to include(an_object_having_attributes(last: an_object_having_attributes(stop_area_id: last_stop_area.id)))
    }
  end
end
