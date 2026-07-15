# frozen_string_literal: true

RSpec.describe Query::Equipment do
  let!(:context) do
    Chouette.create do
      stop_area_provider :searched_stop_area_provider do
        stop_area :searched_stop_area do
          equipment :searched_equipment, name: 'foo', public_code: 'foo-code', fixed: true, out_of_order: true
        end
      end
      stop_area_provider do
        stop_area do
          equipment name: 'bar', public_code: 'bar-code', fixed: false, out_of_order: false
        end
      end
    end
  end

  let(:query) { Query::Equipment.new(Equipment.all) }

  subject(:equipment) { context.equipment(:searched_equipment) }
  let(:stop_area_provider) { context.stop_area_provider(:searched_stop_area_provider) }
  let(:stop_area) { context.stop_area(:searched_stop_area) }

  describe '#text' do
    it 'should return the equipment with name foo' do
      scope = query.text('foo').scope
      expect(scope).to match_array([equipment])
    end

    it 'should return the equipment with public code foo-code' do
      scope = query.text('foo-code').scope
      expect(scope).to eq([equipment])
    end
  end

  describe '#fixed' do
    it 'should return the equipment with fixed true' do
      scope = query.fixed(true).scope
      expect(scope).to eq([equipment])
    end
  end

  describe '#out_of_order' do
    it 'should return the equipment with out_of_order true' do
      scope = query.out_of_order(true).scope
      expect(scope).to eq([equipment])
    end
  end

  describe '#stop_area_id' do
    it 'should return the right equipment' do
      scope = query.stop_area_id(stop_area.id).scope
      expect(scope).to eq([equipment])
    end
  end

  describe '#stop_area_provider_id' do
    it 'should return the right equipment' do
      scope = query.stop_area_provider_id(stop_area_provider.id).scope
      expect(scope).to eq([equipment])
    end
  end
end
