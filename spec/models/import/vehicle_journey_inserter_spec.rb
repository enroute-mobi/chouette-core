# frozen_string_literal: true

RSpec.describe Import::VehicleJourneyInserter do
  let(:context) do
    Chouette.create do
      referential do
        journey_pattern
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
      let(:context) do
        Chouette.create do
          code_space
          referential do
            journey_pattern
          end
        end
      end
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
      let(:context) do
        Chouette.create do
          service_facility_set
          referential do
            journey_pattern
          end
        end
      end
      let(:service_facility_set) { context.service_facility_set }

      before { vehicle_journey.service_facility_sets = [service_facility_set] }

      describe 'saved Vehicle Journey' do
        subject { Chouette::VehicleJourney.first }

        before { insert }

        it { is_expected.to have_attributes(service_facility_sets: containing_exactly(service_facility_set)) }
      end
    end

    context 'when Vehicle Journey is associated to Timetables' do
      let(:context) do
        Chouette.create do
          referential do
            journey_pattern
            2.times { time_table }
          end
        end
      end
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

    context 'when Vehicle Journey is associated to Footnotes' do
      let(:context) do
        Chouette.create do
          referential do
            journey_pattern
            2.times { footnote }
          end
        end
      end
      let(:footnotes) { context.footnotes }

      before do
        footnotes.each do |footnote|
          vehicle_journey.vehicle_journey_footnote_relationships.build(footnote_id: footnote.id)
        end
      end

      it 'saves footnotes_vehicle_journeys in database' do
        expect { subject }.to(
          change { Chouette::Footnote.all.map { |f| f.vehicle_journeys.count } }.from([0, 0]).to([1, 1])
        )
      end
    end
  end
end
