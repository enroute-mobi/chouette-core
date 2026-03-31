# frozen_string_literal: true

RSpec.describe Scope::StopAreaReferential do
  subject(:scope) { described_class.new(stop_area_referential) }

  let(:stop_area_referential) { context.workgroup(:workgroup).stop_area_referential }

  describe '#collection' do
    subject { scope.collection(collection_name, current_collection: nil) }

    let(:global_scope) { double('global_scope') }

    let(:context) do
      Chouette.create do
        workgroup :workgroup do
          stop_area :stop_area, area_type: Chouette::AreaType::QUAY
          stop_area :excluded_stop_place, area_type: Chouette::AreaType::STOP_PLACE

          stop_area :flexible_stop_area, area_type: Chouette::AreaType::FLEXIBLE_STOP_PLACE
          stop_area :stop_area_flexible_member,
                    area_type: Chouette::AreaType::QUAY,
                    flexible_areas: %i[flexible_stop_area]
        end

        workgroup :other_workgroup do
          stop_area :other_stop_area, area_type: Chouette::AreaType::QUAY
          stop_area :other_flexible_stop_area, area_type: Chouette::AreaType::FLEXIBLE_STOP_PLACE
          stop_area :other_stop_area_flexible_member,
                    area_type: Chouette::AreaType::QUAY,
                    flexible_areas: %i[other_flexible_stop_area]
        end
      end
    end

    before do
      allow(global_scope).to receive(:stop_areas).and_return(stop_areas)
      scope.global_scope = global_scope
    end

    context 'with :non_flexible_stop_areas' do
      let(:collection_name) { :non_flexible_stop_areas }

      let(:stop_areas) { Chouette::StopArea.where.not(area_type: Chouette::AreaType::STOP_PLACE) }
      let(:flexible_stop_areas) { Chouette::StopArea.where(area_type: Chouette::AreaType::FLEXIBLE_STOP_PLACE) }

      before { allow(global_scope).to receive(:flexible_stop_areas).and_return(flexible_stop_areas) }

      it 'returns only non-flexible stop areas and members of flexible stop areas in referential' do
        is_expected.to match_array(%i[stop_area stop_area_flexible_member].map { |i| context.stop_area(i) })
      end
    end

    context 'with :flexible_stop_areas' do
      let(:collection_name) { :flexible_stop_areas }

      let(:stop_areas) { context.workgroup(:workgroup).stop_areas }

      it 'returns only non-flexible stop areas in referential' do
        is_expected.to contain_exactly(context.stop_area(:flexible_stop_area))
      end
    end
  end
end
