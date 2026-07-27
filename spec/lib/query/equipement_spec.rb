# frozen_string_literal: true

RSpec.describe Query::Equipement do
  let!(:context) do
    Chouette.create do
      stop_area :searched_stop_area
      stop_area :other_stop_area
      shape_provider :searched_shape_provider do
        equipement :searched_equipement, name: 'foo', public_code: 'foo-code', fixed: true, out_of_order: true,
                                         stop_area: :searched_stop_area
      end
      shape_provider do
        equipement name: 'bar', public_code: 'bar-code', fixed: false, out_of_order: false,
                   stop_area: :other_stop_area
      end
    end
  end

  let(:query) { Query::Equipement.new(Equipement.all) }

  subject(:equipement) { context.equipement(:searched_equipement) }
  let(:shape_provider) { context.shape_provider(:searched_shape_provider) }
  let(:stop_area) { context.stop_area(:searched_stop_area) }

  describe '#text' do
    it 'should return the equipement with name foo' do
      scope = query.text('foo').scope
      expect(scope).to match_array([equipement])
    end

    it 'should return the equipement with public code foo-code' do
      scope = query.text('foo-code').scope
      expect(scope).to eq([equipement])
    end
  end

  describe '#fixed' do
    it 'should return the equipement with fixed true' do
      scope = query.fixed(true).scope
      expect(scope).to eq([equipement])
    end

    it 'should return equipements with fixed false' do
      scope = query.fixed(false).scope
      expect(scope).to_not include(equipement)
      expect(scope).to be_present
    end

    it 'should not filter when value is nil' do
      scope = query.fixed(nil).scope
      expect(scope.count).to eq(Equipement.count)
    end
  end

  describe '#out_of_order' do
    it 'should return the equipement with out_of_order true' do
      scope = query.out_of_order(true).scope
      expect(scope).to eq([equipement])
    end

    it 'should return equipements with out_of_order false' do
      scope = query.out_of_order(false).scope
      expect(scope).to_not include(equipement)
      expect(scope).to be_present
    end
  end

  describe '#stop_area_id' do
    it 'should return the right equipement' do
      scope = query.stop_area_id(stop_area.id).scope
      expect(scope).to eq([equipement])
    end
  end

  describe '#shape_provider_id' do
    it 'should return the right equipement' do
      scope = query.shape_provider_id(shape_provider.id).scope
      expect(scope).to eq([equipement])
    end
  end
end
