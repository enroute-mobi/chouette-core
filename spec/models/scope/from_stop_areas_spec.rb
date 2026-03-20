# frozen_string_literal: true

RSpec.describe Scope::FromStopAreas do
  subject(:scope) { described_class.new }

  describe '#collection' do
    subject { scope.collection(collection_name, current_collection: current_collection) }

    let(:global_scope) { double('global_scope') }
    let(:stop_areas) { Chouette::StopArea.where(id: context.stop_area(:stop_area)) }
    let(:allow_stop_areas) { allow(global_scope).to receive(:stop_areas).and_return(stop_areas) }

    before { scope.global_scope = global_scope }

    context 'with :stop_area_groups' do
      let(:collection_name) { :stop_area_groups }
      let(:current_collection) { StopAreaGroup.all }

      let(:context) do
        Chouette.create do
          stop_area :stop_area
          stop_area :other_stop_area

          stop_area_group :stop_area_group, stop_areas: %i[stop_area]
          stop_area_group :other_stop_area_group, stop_areas: %i[other_stop_area]
        end
      end

      before { allow_stop_areas }

      it 'returns only stop area groups associated to stop areas' do
        is_expected.to contain_exactly(context.stop_area_group(:stop_area_group))
      end
    end

    context 'with :entrances' do
      let(:collection_name) { :entrances }
      let(:current_collection) { Entrance.all }

      let(:context) do
        Chouette.create do
          stop_area :stop_area do
            entrance :entrance
          end
          stop_area :other_stop_area do
            entrance :other_entrance
          end
        end
      end

      before { allow_stop_areas }

      it 'returns only entrances associated to stop areas' do
        is_expected.to contain_exactly(context.entrance(:entrance))
      end
    end
  end
end
