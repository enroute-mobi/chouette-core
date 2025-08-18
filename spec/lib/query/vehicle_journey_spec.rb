# frozen_string_literal: true

RSpec.describe Query::VehicleJourney do
  subject(:query) { Query::VehicleJourney.new(scope) }

  let(:scope) { Chouette::VehicleJourney.all }

  before(:each) do
    context.referential.switch
  end

  describe '#text' do
    let(:context) do
      Chouette.create do
        vehicle_journey
      end
    end

    let(:vehicle_journey) { context.vehicle_journey }

    context 'when published journey name is the vehicle journey published journey name' do
      subject { query.text(vehicle_journey.published_journey_name).scope }

      it 'includes vehicle journey' do
        is_expected.to include(vehicle_journey)
      end
    end

    context 'when objectid is a part of the vehicle journey objectid' do
      subject { query.text(vehicle_journey.objectid.last(20)).scope }

      it 'includes vehicle journey' do
        is_expected.to include(vehicle_journey)
      end
    end

    context 'when published journey name is not the vehicle journey published journey name' do
      subject { query.text('test').scope }

      it 'not includes vehicle journey' do
        is_expected.not_to include(vehicle_journey)
      end
    end
  end

  describe '#journey_pattern_id' do
    subject { query.journey_pattern_id(value).scope }

    let(:context) do
      Chouette.create do
        journey_pattern :match_journey_pattern do
          vehicle_journey :match
        end

        journey_pattern do
          vehicle_journey :other
        end
      end
    end

    context 'without value' do
      let(:value) { nil }

      it 'returns all vehicle journeys' do
        is_expected.to eq(scope)
      end
    end

    context 'with the id of a journey pattern' do
      let(:value) { context.journey_pattern(:match_journey_pattern).id }

      it 'returns only vehicle journeys having this journey pattern' do
        is_expected.to match_array([context.vehicle_journey(:match)])
      end
    end
  end

  describe '#company' do
    let(:context) do
      Chouette.create do
        company :other_company

        vehicle_journey
      end
    end

    let(:company_id) { context.vehicle_journey.route.line.company_id }
    let(:other_company_id) { context.company(:other_company).id }
    let(:vehicle_journey) { context.vehicle_journey }

    context 'when company is the vehicle journey company' do
      subject { query.company(company_id).scope }

      it 'includes vehicle journey' do
        is_expected.to include(vehicle_journey)
      end
    end

    context 'when company is not the vehicle journey company' do
      subject { query.company(other_company_id).scope }

      it 'not includes vehicle journey' do
        is_expected.not_to include(vehicle_journey)
      end
    end
  end

  describe '#line' do
    let(:context) do
      Chouette.create do
        vehicle_journey

        line(:other)
      end
    end

    let(:line_id) { context.vehicle_journey.route.line_id }
    let(:other_line_id) { context.line(:other).id }
    let(:vehicle_journey) { context.vehicle_journey }

    context 'when line is the vehicle journey line' do
      subject { query.line(line_id).scope }

      it 'includes vehicle journey' do
        is_expected.to include(vehicle_journey)
      end
    end

    context 'when line is not the vehicle journey line' do
      subject { query.line(other_line_id).scope }

      it 'not includes vehicle journey ' do
        is_expected.not_to include(vehicle_journey)
      end
    end
  end

  describe '#time_table' do
    let(:context) do
      Chouette.create do
        time_table :time_table
        time_table :other_time_table

        vehicle_journey time_tables: [:time_table]
      end
    end

    let(:vehicle_journey) { context.vehicle_journey }
    let(:time_table) { context.time_table(:time_table) }
    let(:other_time_table) { context.time_table(:other_time_table) }

    context "when vehicle journey include timetable" do
      subject { query.time_table(time_table).scope }

      it 'includes vehicle journey' do
        is_expected.to include(vehicle_journey)
      end
    end

    context "when vehicle journey not include timetable" do
      subject { query.time_table(other_time_table).scope }

      it 'not includes vehicle journey ' do
        is_expected.not_to include(vehicle_journey)
      end
    end
  end

  describe '#with_time_table' do
    subject { query.with_time_table(value).scope }

    let(:context) do
      Chouette.create do
        time_table :time_table

        vehicle_journey :vehicle_journey_with_time_table, time_tables: [:time_table]
        vehicle_journey :vehicle_journey_without_time_table
      end
    end

    context 'when given value is blank' do
      let(:value) { nil }

      it 'returns all vehicle journeys' do
        is_expected.to eq(scope)
      end
    end

    context 'when given value is false' do
      let(:value) { false }

      it 'returns all vehicle journeys' do
        is_expected.to match_array([context.vehicle_journey(:vehicle_journey_without_time_table)])
      end
    end

    context 'when given value is true' do
      let(:value) { true }

      it 'returns only vehicle journeys without time table' do
        is_expected.to eq(scope)
      end
    end
  end

  describe '#time_table_period' do
    let(:context) do
      Chouette.create do
        time_table :time_table

        vehicle_journey time_tables: [:time_table]
      end
    end

    let(:vehicle_journey) { context.vehicle_journey }
    let(:time_table) { context.time_table(:time_table) }
    let(:included_range) { time_table.start_date..time_table.end_date }
    let(:excluded_range) { (time_table.end_date + 5.days)..(time_table.end_date + 10.days) }

    context "when range intersects one vehicle journey's timetable" do
      subject { query.time_table_period(included_range).scope }

      it 'includes vehicle journey' do
        is_expected.to include(vehicle_journey)
      end
    end

    context "when range doesn't intersect one vehicle journey's timetable" do
      subject { query.time_table_period(excluded_range).scope }

      it 'not includes vehicle journey ' do
        is_expected.not_to include(vehicle_journey)
      end
    end
  end

  describe '#between_stop_areas' do
    let(:context) do
      Chouette.create do
        vehicle_journey

        stop_area(:other)
      end
    end

    let(:vehicle_journey) { context.vehicle_journey }
    let(:first_vehicle_journey_stop_area) { context.vehicle_journey.vehicle_journey_at_stops.first.stop_point.stop_area }
    let(:last_vehicle_journey_stop_area) { context.vehicle_journey.vehicle_journey_at_stops.last.stop_point.stop_area }
    let(:other_stop_area) { context.stop_area(:other) }

    context 'when stop areas are the vehicle journey stop areas' do
      it 'includes vehicle journey with first stop area' do
        scope = query.between_stop_areas(first_vehicle_journey_stop_area.id, nil).scope
        expect(scope).to include(vehicle_journey)
      end

      it 'includes vehicle journey with first and last stop areas' do
        scope = query.between_stop_areas(first_vehicle_journey_stop_area.id, last_vehicle_journey_stop_area.id).scope
        expect(scope).to include(vehicle_journey)
      end
    end

    context 'when stop areas are not the vehicle journey stop areas' do
      it 'not includes vehicle journey' do
        scope = query.between_stop_areas(other_stop_area.id, nil).scope
        expect(scope).not_to include(vehicle_journey)
      end
    end
  end

  describe '#where_departure_time_between' do
    subject { query.where_departure_time_between(start_time, end_time, allow_empty: allow_empty).scope }

    let(:context) do
      Chouette.create do
        vehicle_journey
      end
    end
    let(:allow_empty) { double(:allow_empty) }

    context 'when start_time and end_date empty' do
      let(:start_time) { nil }
      let(:end_time) { nil }

      it 'returns all vehicle journeys' do
        is_expected.to eq(scope)
      end
    end

    context 'start_time and end_time are not empty' do
      let(:start_time) { double(:start_time) }
      let(:end_time) { double(:end_time) }

      it 'passes paramaters to scope #where_departure_time_between' do
        expect(scope).to receive(:where_departure_time_between).with(start_time, end_time, allow_empty: allow_empty)
        subject
      end
    end
  end
end
