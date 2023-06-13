RSpec.describe Query::Entrance do

  let!(:context) do
    Chouette.create do
      stop_area_provider :searched_stop_area_provider do
        stop_area :searched_stop_area do
          entrance :searched_entrance, name: 'foo', entrance_type: 'opening', city_name: 'foo', entry_flag: true, exit_flag: true
        end
      end
      stop_area_provider do
        stop_area do
          entrance name: 'bar', entrance_type: 'open_door', city_name: 'bar', entry_flag: false, exit_flag: false
        end
      end
    end
  end

  let(:query) { Query::Entrance.new(Entrance.all) }

  subject(:entrance) { context.entrance(:searched_entrance) }
  let(:stop_area_provider) { context.stop_area_provider(:searched_stop_area_provider) }
  let(:stop_area) { context.stop_area(:searched_stop_area) }

  let(:scope) { query.send(criteria_id, criteria_value).scope }

  describe '#text' do
    describe 'when search by id' do
      let(:criteria_id) { 'text' }
      let(:criteria_value) { '99999' }
      it { is_expected.to be_truthy }
    end
    describe 'when search by name' do
      let(:criteria_id) { 'text' }
      let(:criteria_value) { 'Stop area selected' }
      it { is_expected.to be_truthy }
    end
    describe 'when search by short name' do
      let(:criteria_id) { 'text' }
      let(:criteria_value) { 'short_name' }
      it { is_expected.to be_truthy }
    end
  end

  describe '#entrance_type' do
    it 'should return the entrance with type opening' do
      scope = query.entrance_type('opening').scope
      expect(scope).to eq([entrance])
    end
  end

  describe '#city_name' do
    it 'should return the entrance with city_name foo' do
      scope = query.city_name('foo').scope
      expect(scope).to eq([entrance])
    end
  end

  describe '#entry_flag' do
    it 'should return the entrance with entry_flag true' do
      scope = query.entry_flag(true).scope
      expect(scope).to eq([entrance])
    end
  end

  describe '#exit_flag' do
    it 'should return the entrance with exit_flag true' do
      scope = query.exit_flag(true).scope
      expect(scope).to eq([entrance])
    end
  end

  describe '#stop_area_id' do
    it 'should return the right entrance' do
      scope = query.stop_area_id(stop_area.id).scope
      expect(scope).to eq([entrance])
    end
  end

  describe '#stop_area_provider_id' do
    it 'should return the right entrance' do
      scope = query.stop_area_provider_id(stop_area_provider.id).scope
      expect(scope).to eq([entrance])
    end
  end
end
