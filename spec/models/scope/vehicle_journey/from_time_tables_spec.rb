# frozen_string_literal: true

RSpec.describe Scope::VehicleJourney::FromTimeTables do
  let(:scope) { described_class.new }

  describe '#collection' do
    subject { scope.collection(collection_name, current_collection: current_collection) }

    let(:global_scope) { double('glocal_scope') }

    before do
      allow(global_scope).to receive(:time_tables).and_return(
        Chouette::TimeTable.where(id: context.time_table(:time_table))
      )
      scope.global_scope = global_scope
    end

    context 'with :vehicle_journeys' do
      let(:collection_name) { :vehicle_journeys }
      let(:current_collection) { Chouette::VehicleJourney.all }

      let(:context) do
        Chouette.create do
          time_table :time_table
          time_table :other_time_table

          vehicle_journey :vehicle_journey, time_tables: %i[time_table]
          vehicle_journey :other_vehicle_journey, time_tables: %i[other_time_table]
        end
      end
      let(:line_ids) { [context.line(:line).id] }

      before { context.referential.switch }

      it 'returns only vehicle journeys associated to time tables' do
        is_expected.to contain_exactly(context.vehicle_journey(:vehicle_journey))
      end
    end
  end
end
