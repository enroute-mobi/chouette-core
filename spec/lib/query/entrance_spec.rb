RSpec.describe Query::Entrance do
  let(:query) { Query::Entrance.new(Entrance.all) }

  let(:stop_area) { create(:stop_area) }
  let(:stop_area_provider) { stop_area.stop_area_provider }

  def run_test(name, true_value, false_value)
    base_attribute = { name: 'test', stop_area_provider_id: stop_area_provider.id }
    first_attributes = {}.tap { |h| h[name] = true_value }
    last_attributes = {}.tap { |h| h[name] = false_value }

    first = stop_area.entrances.create(base_attribute.merge(first_attributes))
    last = stop_area.entrances.create(base_attribute.merge(last_attributes))

    scope = query.send(name, true_value).scope

    expect(scope).to include(first)
    expect(scope).not_to include(last)
  end

  {
    name: ['foo', 'bar'],
    entrance_type: ['opening', 'open_door'],
    city_name: ['foo', 'bar'],
    entry_flag: [true, false],
    exit_flag: [true, false],
  }.each do |name, (true_value, false_value)|
    describe "##{name}" do
      it 'should return the right entrance' do
        run_test(name, true_value, false_value)
      end
    end
  end

  describe '#stop_area_id' do
    it 'should return the right entrance' do
      run_test(:stop_area_id, stop_area.id, (stop_area.id + 1))
    end
  end

  describe '#stop_area_provider_id' do
    it 'should return the right entrance' do
      run_test(:stop_area_provider_id, stop_area_provider.id, (stop_area_provider.id + 1))
    end
  end
end
