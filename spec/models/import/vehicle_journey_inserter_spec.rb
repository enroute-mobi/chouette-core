# frozen_string_literal: true

RSpec.describe Import::VehicleJourneyInserter do
  let(:context) do
    Chouette.create do
      code_space
      stop_area :departure
      stop_area :arrival

      referential do
        journey_pattern

        2.times { time_table }
      end
    end
  end

  let(:referential) { context.referential }
  let(:journey_pattern) { context.journey_pattern }

  before { referential.switch }

  let(:referential_inserter) do
    ReferentialInserter.new referential do |config|
      config.add IdInserter
      config.add TimestampsInserter
      config.add CopyInserter
    end
  end

  subject(:vehicle_journey_inserter) do
    Import::VehicleJourneyInserter.new referential_inserter, on_invalid: on_invalid, on_save: on_save
  end

  let(:on_invalid) { proc {} }
  let(:on_save) { proc {} }

  let(:vehicle_journey) do
    journey_pattern.vehicle_journeys.build(route: journey_pattern.route) do |vehicle_journey|
      vehicle_journey.vehicle_journey_at_stops.tap do |stops|
        journey_pattern.route.stop_points.each_with_index do |stop_point, index|
          passing_time = TimeOfDay.new(12 + index)
          stops.build stop_point: stop_point, arrival_time_of_day: passing_time, departure_time_of_day: passing_time
        end
      end
    end
  end

  describe '#insert' do
    subject(:insert) do
      vehicle_journey_inserter.insert vehicle_journey
      referential_inserter.flush
    end

    context 'when VehicleJourney is invalid' do
      before do
        vehicle_journey.vehicle_journey_at_stops.each do |stop|
          stop.arrival_time_of_day = TimeOfDay.new(0)
        end
      end

      it 'invokes the on_invalid callback' do
        expect(on_invalid).to receive(:call).with(vehicle_journey)
        subject
      end
    end

    it 'saves the VehicleJourney in database' do
      expect { subject }.to change { Chouette::VehicleJourney.count }.from(0).to(1)
    end

    it 'saves the VehicleJourneyAtStops in database' do
      expect { subject }.to change { Chouette::VehicleJourneyAtStop.count }.from(0).to(3)
    end

    it 'invokes the on_save callback' do
      expect(on_save).to receive(:call).with(vehicle_journey)
      subject
    end

    context 'when Vehicle Journey has codes' do
      let(:code_space) { context.code_space }

      before do
        2.times do |n|
          vehicle_journey.codes.build code_space: code_space, value: n
        end
      end

      it 'saves the ReferentialCodes in database' do
        expect { subject }.to change { ReferentialCode.count }.from(0).to(2)
      end
    end

    context 'when Vehicle Journey has service_facility_sets' do
      let(:service_facility_set) do
        referential.workbench.default_shape_provider.service_facility_sets.create!(
          name: 'Test',
          associated_services: ['luggage_carriage/cycles_allowed']
        )
      end

      before { vehicle_journey.service_facility_sets = [service_facility_set] }

      describe 'saved Vehicle Journey' do
        subject { Chouette::VehicleJourney.first }

        before { insert }

        it { is_expected.to have_attributes(service_facility_sets: containing_exactly(service_facility_set)) }
      end
    end

    context 'when Vehicle Journey is associated to Timetables' do
      let(:timetables) { context.time_tables }

      before do
        timetables.each do |timetable|
          vehicle_journey.vehicle_journey_time_table_relationships.build(time_table_id: timetable.id)
        end
      end

      it 'saves the Chouette::TimeTablesVehicleJourney in database' do
        expect { subject }.to change { Chouette::TimeTablesVehicleJourney.count }.from(0).to(2)
      end
    end
  end
end
