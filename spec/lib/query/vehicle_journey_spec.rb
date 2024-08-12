# frozen_string_literal: true

RSpec.describe Query::VehicleJourney do

  let(:query) { Query::VehicleJourney.new(Chouette::VehicleJourney.all) }

  describe '#text' do
    let(:context) do
      Chouette.create do
        vehicle_journey
      end
    end

    let(:vehicle_journey) { context.vehicle_journey }

    before(:each) do
      context.referential.switch
    end

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

    before(:each) do
      context.referential.switch
    end

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

    before(:each) do
      context.referential.switch
    end

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

    before(:each) do
      context.referential.switch
    end

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

    before(:each) do
      context.referential.switch
    end

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

    before(:each) do
      context.referential.switch
    end

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

end
