# frozen_string_literal: true

RSpec.describe Scope::Export::Stateful do
  subject(:scope) { described_class.new(export.id) }

  let(:referential) { context.referential }
  let(:export) do
    referential.workbench.exports.create!(
      type: 'Export::Gtfs',
      name: 'Test',
      creator: 'test',
      referential: referential,
      workgroup: referential.workgroup,
      setup: { scope_setup: { type: 'Export::Setup::Scope::Referential' } }
    )
  end

  before { referential.switch }

  describe '#collection' do
    subject { scope.collection(collection_name, current_collection: current_collection) }

    [
      [
        :vehicle_journeys,
        Chouette::VehicleJourney,
        proc do
          Chouette.create do
            referential do
              vehicle_journey :vehicle_journey
              vehicle_journey :other_vehicle_journey
            end
          end
        end
      ],
      [
        :time_tables,
        Chouette::TimeTable,
        proc do
          Chouette.create do
            referential do
              time_table :time_table
              time_table :other_time_table
            end
          end
        end
      ]
    ].each do |collection_name, model_class, context_proc|
      model_name = collection_name.to_s.singularize.to_sym

      context "with #{collection_name.inspect}" do
        let(:collection_name) { collection_name }
        let(:model) { context.send(model_name, model_name) }
        let(:current_collection) { model_class.where(id: model) }

        let(:context) { context_proc.call }

        it 'returns models from scope' do
          is_expected.to contain_exactly(model)
        end

        it 'creates exportables' do
          expect { subject }.to(
            change { Exportable.all }.from(be_empty)
                                    .to(
                                      contain_exactly(have_attributes(export: export, model: model, processed: false))
                                    )
          )
        end

        context 'when already loaded' do
          before { scope.collection(collection_name, current_collection: model_class.where(id: model)) }

          let(:current_collection) { nil } # so that the model can only be retrieved through cache

          it 'returns models from scope using exportables cache' do
            is_expected.to contain_exactly(model)
          end

          it 'does not creates new exportables' do
            expect { subject }.not_to(change { Exportable.count })
          end
        end
      end
    end
  end
end
