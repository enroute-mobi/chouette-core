# frozen_string_literal: true

RSpec.describe Scope::VehicleJourney::ByLines do
  let(:scope) { described_class.new(line_ids) }

  describe '#collection' do
    subject { scope.collection(collection_name, current_collection: current_collection) }

    context 'with :vehicle_journeys' do
      let(:collection_name) { :vehicle_journeys }
      let(:current_collection) { Chouette::VehicleJourney.all }

      let(:context) do
        Chouette.create do
          line :line
          line :other_line

          referential do
            route line: :line do
              vehicle_journey :vehicle_journey
            end
            route line: :other_line do
              vehicle_journey :other_vehicle_journey
            end
          end
        end
      end
      let(:line_ids) { [context.line(:line).id] }

      before { context.referential.switch }

      it 'returns only vehicle journeys associated to lines' do
        is_expected.to contain_exactly(context.vehicle_journey(:vehicle_journey))
      end
    end

    context 'with metadatas' do
      let(:collection_name) { :metadatas }
      let(:current_collection) { context.referential.metadatas }

      let(:context) do
        Chouette.create do
          line :line
          line :other_line

          referential
        end.tap do |context|
          context.referential.metadatas.create!(
            lines: [context.line(:line)],
            periodes: [Time.zone.yesterday..Time.zone.today]
          )
          context.referential.metadatas.create!(
            lines: [context.line(:other_line)],
            periodes: [Time.zone.today..Time.zone.tomorrow]
          )
        end
      end
      let(:line_ids) { [context.line(:line).id] }

      it 'returns only metadatas associated to lines' do
        is_expected.to contain_exactly(have_attributes(periodes: [Time.zone.yesterday..Time.zone.today]))
      end
    end
  end
end
