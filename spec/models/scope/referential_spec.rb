# frozen_string_literal: true

RSpec.describe Scope::Referential do
  let(:scope) { described_class.new(referential) }

  let(:referential) { context.referential(:referential) }

  describe '#collection' do
    subject { scope.collection(collection_name, current_collection: nil) }

    let(:global_scope) { double('glocal_scope') }

    before { scope.global_scope = global_scope }

    context 'with :organisations' do
      let(:collection_name) { :organisations }
      let(:metadatas) { referential.metadatas }

      before { allow(global_scope).to receive(:metadatas).and_return(metadatas) }

      context 'without metadatas' do
        let(:context) do
          Chouette.create do
            organisation :organisation
            organisation :other_organisation

            workbench organisation: :organisation do
              referential :referential
            end
          end
        end

        it 'returns referential organisation' do
          is_expected.to contain_exactly(context.organisation(:organisation))
        end
      end

      context 'with metadatas' do
        let(:context) do
          Chouette.create do
            organisation :organisation
            organisation :organisation1
            organisation :organisation2
            organisation :other_organisation

            line :line

            workbench organisation: :organisation do
              referential :referential
            end
            workbench organisation: :organisation1 do
              referential :referential1
            end
            workbench organisation: :organisation2 do
              referential :referential2
            end
          end.tap do |context|
            %i[referential1 referential2].each do |referential|
              context.referential(:referential).metadatas.create!(
                lines: [context.line(:line)],
                referential_source: context.referential(referential),
                periodes: [Time.zone.yesterday..Time.zone.tomorrow]
              )
            end
            context.referential(:referential).metadatas.create!(
              lines: [context.line(:line)],
              periodes: [Time.zone.yesterday..Time.zone.tomorrow]
            )
          end
        end

        it 'returns organisations in metadatas' do
          is_expected.to contain_exactly(context.organisation(:organisation1), context.organisation(:organisation2))
        end
      end
    end

    context 'with :validity_period' do
      let(:collection_name) { :validity_period }

      let(:validity_period) { Time.zone.yesterday..Time.zone.tomorrow }
      let(:referential) { instance_double(Referential, 'referential', validity_period: validity_period) }

      it { is_expected.to be_a(Period) }

      it 'is equal to referential validity period' do
        is_expected.to eq(validity_period)
      end
    end
  end
end
