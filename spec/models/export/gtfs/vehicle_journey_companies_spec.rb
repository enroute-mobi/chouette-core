# frozen_string_literal: true

RSpec.describe Export::Gtfs::VehicleJourneyCompanies do
  subject(:part) do
    Export::Gtfs::VehicleJourneyCompanies.new export
  end

  let(:export_scope) { Export::Scope::All.new context.referential }

  let(:export) do
    Export::Gtfs.new export_scope: export_scope, workgroup: context.workgroup
  end

  describe '#perform' do
    let(:context) do
      Chouette.create do
        company :first, name: 'dummy1'
        company :second, name: 'dummy2'

        vehicle_journey :first, objectid: 'objectid1', company: :first
        vehicle_journey :second, objectid: 'objectid2', company: :second
      end
    end

    let(:first_company) { context.company(:first) }
    let(:second_company) { context.company(:second) }
    let(:first_vehicle_journey) { context.vehicle_journey(:first) }
    let(:second_vehicle_journey) { context.vehicle_journey(:second) }
    let(:line) { first_vehicle_journey.line }

    before do
      part.index.register_trip_id(first_vehicle_journey, 'trip_1')
      part.index.register_trip_id(second_vehicle_journey, 'trip_2')

      context.referential.switch

      line.update(company: second_company)
    end

    describe 'exported attributes' do
      subject { export.target.attributions.map(&:trip_id) }

      before { part.perform }

      it 'should export attribution of the first vehicle_journey - company' do
        is_expected.to include('trip_1')
      end

      it 'should not export attribution of the second vehicle_journey - company' do
        is_expected.not_to include(second_vehicle_journey.objectid)
      end
    end
  end
end
