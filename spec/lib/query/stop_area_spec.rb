RSpec.describe Query::StopArea do
  describe '#self_and_ancestors' do
    let(:context) do
      Chouette.create do
        stop_area :group_of_stop_places, area_type: 'gdl'
        stop_area :stop_place, area_type: 'lda', parent: :group_of_stop_places
        stop_area :monomodal_stop_place, area_type: 'zdlp', parent: :stop_place
        stop_area :quay, parent: :monomodal_stop_place
      end
    end

    let(:group_of_stop_places) { context.stop_area :group_of_stop_places }
    let(:stop_place) { context.stop_area :stop_place }
    let(:monomodal_stop_place) { context.stop_area :monomodal_stop_place }
    let(:stop_area) { context.stop_area :quay }

    let(:relation) { Chouette::StopArea.where(id: stop_area) }
    subject { Query::StopArea.new(Chouette::StopArea).self_and_ancestors(relation) }

    it 'includes the (Quay) StopArea' do
      is_expected.to include(stop_area)
    end

    it 'includes its Monomodal Stop Place parent' do
      is_expected.to include(monomodal_stop_place)
    end

    it 'includes its Stop Place parent' do
      is_expected.to include(stop_place)
    end

    it 'includes its Group Of Stop Places parent' do
      is_expected.to include(group_of_stop_places)
    end
  end

  describe '#ancestors' do
    let(:context) do
      Chouette.create do
        stop_area :group_of_stop_places, area_type: 'gdl'
        stop_area :stop_place, area_type: 'lda', parent: :group_of_stop_places
        stop_area :monomodal_stop_place, area_type: 'zdlp', parent: :stop_place
        stop_area :quay, parent: :monomodal_stop_place
      end
    end

    let(:group_of_stop_places) { context.stop_area :group_of_stop_places }
    let(:stop_place) { context.stop_area :stop_place }
    let(:monomodal_stop_place) { context.stop_area :monomodal_stop_place }
    let(:stop_area) { context.stop_area :quay }

    let(:relation) { Chouette::StopArea.where(id: stop_area) }
    subject { Query::StopArea.new(Chouette::StopArea).ancestors(relation) }

    it "doesn't include the (Quay) StopArea" do
      is_expected.to_not include(stop_area)
    end

    it 'includes its Monomodal Stop Place parent' do
      is_expected.to include(monomodal_stop_place)
    end

    it 'includes its Stop Place parent' do
      is_expected.to include(stop_place)
    end

    it 'includes its Group Of Stop Places parent' do
      is_expected.to include(group_of_stop_places)
    end
  end

  describe '#self_referents_and_ancestors' do
    let(:context) do
      Chouette.create do
        stop_area :group_of_stop_places, area_type: 'gdl'
        stop_area :stop_place, area_type: 'lda', parent: :group_of_stop_places
        stop_area :monomodal_stop_place, area_type: 'zdlp', parent: :stop_place
        stop_area :referent, parent: :monomodal_stop_place, is_referent: true
        stop_area :quay, referent: :referent
      end
    end

    let(:group_of_stop_places) { context.stop_area :group_of_stop_places }
    let(:stop_place) { context.stop_area :stop_place }
    let(:monomodal_stop_place) { context.stop_area :monomodal_stop_place }
    let(:referent) { context.stop_area :referent }
    let(:stop_area) { context.stop_area :quay }

    let(:relation) { Chouette::StopArea.where(id: stop_area) }
    subject { Query::StopArea.new(Chouette::StopArea).self_referents_and_ancestors(relation) }

    it 'includes the (Quay) StopArea' do
      is_expected.to include(stop_area)
    end

    it 'includes the referent' do
      is_expected.to include(referent)
    end

    it 'includes its Monomodal Stop Place referent parent' do
      is_expected.to include(monomodal_stop_place)
    end

    it 'includes its Stop Place referent parent' do
      is_expected.to include(stop_place)
    end

    it 'includes its Group Of Stop Places referent parent' do
      is_expected.to include(group_of_stop_places)
    end
  end
end
