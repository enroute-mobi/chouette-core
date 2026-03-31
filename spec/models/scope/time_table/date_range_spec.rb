# frozen_string_literal: true

RSpec.describe Scope::TimeTable::DateRange do
  subject(:scope) { described_class.new(date_range) }

  let(:date_range) { Date.parse('2030-01-10')..Date.parse('2030-01-20') }

  describe '#collection' do
    subject { scope.collection(collection_name, current_collection: current_collection) }

    context 'with :time_tables' do
      let(:collection_name) { :time_tables }
      let(:current_collection) { Chouette::TimeTable.all }

      let(:context) do
        Chouette.create do
          time_table :time_table_included, dates_included: [Date.parse('2030-01-15')]
          time_table :time_table_periods_included, periods: [Period.from(Date.parse('2030-01-13')).during(5.days)]
          time_table :time_table_periods_overlapped, periods: [Period.from(Date.parse('2030-01-05')).during(20.days)]
          time_table :time_table_periods_excluded,
                     periods: [Period.from(Date.parse('2030-01-05')).during(20.days)],
                     dates_excluded: (10..20).map { |i| Date.parse("2030-01-#{i}") }
          time_table :time_table_periods_day_types_excluded,
                     periods: [Period.from(Date.parse('2030-01-05')).during(20.days)],
                     int_day_types: 0
        end
      end

      before { context.referential.switch }

      it 'returns only time tables applied in date range' do
        is_expected.to(
          match_array(
            %i[time_table_included time_table_periods_included time_table_periods_overlapped].map do |i|
              context.time_table(i)
            end
          )
        )
      end
    end

    context 'with :vehicle_journeys' do
      let(:collection_name) { :vehicle_journeys }
      let(:current_collection) { Chouette::VehicleJourney.all }

      let(:context) do
        Chouette.create do
          time_table :time_table_included, dates_included: [Date.parse('2030-01-15')]
          time_table :time_table_periods_included, periods: [Period.from(Date.parse('2030-01-13')).during(5.days)]
          time_table :time_table_periods_overlapped, periods: [Period.from(Date.parse('2030-01-05')).during(20.days)]
          time_table :time_table_periods_excluded,
                     periods: [Period.from(Date.parse('2030-01-05')).during(20.days)],
                     dates_excluded: (10..20).map { |i| Date.parse("2030-01-#{i}") }
          time_table :time_table_periods_day_types_excluded,
                     periods: [Period.from(Date.parse('2030-01-05')).during(20.days)],
                     int_day_types: 0

          vehicle_journey :vj_time_table_included, time_tables: %i[time_table_included]
          vehicle_journey :vj_time_table_periods_included, time_tables: %i[time_table_periods_included]
          vehicle_journey :vj_time_table_periods_overlapped, time_tables: %i[time_table_periods_overlapped]
          vehicle_journey :vj_time_table_periods_excluded, time_tables: %i[time_table_periods_excluded]
          vehicle_journey :vj_time_table_periods_day_types_excluded,
                          time_tables: %i[time_table_periods_day_types_excluded]
        end
      end

      before { context.referential.switch }

      it 'returns only vehicle journeus applied in date range' do
        is_expected.to(
          match_array(
            %i[vj_time_table_included vj_time_table_periods_included vj_time_table_periods_overlapped].map do |i|
              context.vehicle_journey(i)
            end
          )
        )
      end
    end

    context 'with :metadatas' do
      let(:collection_name) { :metadatas }
      let(:current_collection) { double('metadatas') }

      it 'calls #include_daterange on current collection' do
        expect(current_collection).to receive(:include_daterange).with(date_range).and_return(:result)
        is_expected.to eq(:result)
      end
    end

    context 'with :validity_period' do
      let(:collection_name) { :validity_period }
      let(:current_collection) { Date.parse('2030-01-01')..Date.parse('2030-01-15') }

      it 'restricts current value to date range' do
        is_expected.to eq(Date.parse('2030-01-10')..Date.parse('2030-01-15'))
      end
    end
  end
end
