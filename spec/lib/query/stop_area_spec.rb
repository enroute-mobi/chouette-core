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

  describe '#query' do

    let(:query) { Query::StopArea.new(Chouette::StopArea.all) }
    let(:context) do
      Chouette.create do
        stop_area :selected, {
          id: 9999999,
          name: "Stop area selected",
          area_type: "zdep",
          zip_code: '44300',
          city_name: 'Nantes',
          is_referent: true ,
        }
        stop_area :parent, name: "Stop area 1", area_type: "gdl", zip_code: '44000'
        stop_area :other, name: "Stop area 2", area_type: "lda", zip_code: '44100'

        stop_area_provider :stop_area_provider_selected
      end
    end
    let(:selected) { context.stop_area :selected }
    let(:parent) { context.stop_area :parent }
    let(:other) { context.stop_area :other }

    let(:scope) { query.send(criteria_id, criteria_value).scope }

    subject { scope == [selected] }

    describe '#name' do
      let(:criteria_id) { 'name' }
      let(:criteria_value) { 'Stop area selected' }

      it { is_expected.to be_truthy }
    end

    describe '#area_type' do
      let(:criteria_id) { 'area_type' }
      let(:criteria_value) { 'zdep' }

      it { is_expected.to be_truthy }
    end

    describe '#zip_code' do
      let(:criteria_id) { 'zip_code' }
      let(:criteria_value) { '44300' }

      it { is_expected.to be_truthy }
    end

    describe '#city_name' do
      let(:criteria_id) { 'city_name' }
      let(:criteria_value) { 'Nantes' }

      it { is_expected.to be_truthy }
    end

    describe '#stop_area_provider_id' do
      let(:stop_area_provider_selected) { context.stop_area_provider(:stop_area_provider_selected) }
      let(:criteria_id) { 'stop_area_provider_id' }
      let(:criteria_value) { selected.stop_area_provider.id }

      before { selected.update stop_area_provider: stop_area_provider_selected}

      it { is_expected.to be_truthy }
    end

    describe '#is_referent' do
      let(:criteria_id) { 'is_referent' }
      let(:criteria_value) { true }

      it { is_expected.to be_truthy }
    end

    describe '#parent_id' do
      let(:criteria_id) { 'parent_id' }
      let(:criteria_value) { parent.id }

      before { selected.update parent: parent}

      it { is_expected.to be_truthy }
    end

    describe '#statuses' do
      let(:criteria_id) { 'statuses' }

      context 'when value is confirmed' do
        before do
          parent.update deleted_at: Time.now
          other.update deleted_at: Time.now
          selected.update confirmed_at: Time.now, deleted_at: nil
        end

        let(:criteria_value) { 'confirmed' }

        it { is_expected.to be_truthy }
      end

      context 'when value is in_creation' do
        before do
          parent.update deleted_at: Time.now
          other.update deleted_at: Time.now
          selected.update confirmed_at: nil, deleted_at: nil
        end

        let(:criteria_value) { 'in_creation' }

        it { is_expected.to be_truthy }
      end

      context 'when value is deactivated' do
        before do
          parent.update confirmed_at: nil, deleted_at: nil
          other.update confirmed_at: nil, deleted_at: nil
          selected.update deleted_at: Time.now
        end

        let(:criteria_value) { 'deactivated' }

        it { is_expected.to be_truthy }
      end

      context 'when value is multiple' do
        before do
          parent.update confirmed_at: nil, deleted_at: nil
          other.update confirmed_at: Time.now, deleted_at: nil
          selected.update deleted_at: Time.now
        end

        let(:criteria_value) { ['deactivated', 'in_creation', 'confirmed'] }
        subject { scope }

        it { is_expected.to match_array([ selected, parent, other]) }
      end

    end
  end
end
