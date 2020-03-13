
RSpec.describe TomTom::Delegator do

  let(:coster) { double }
  subject(:delegator_coster) { TomTom::Delegator.new(coster) }

  let(:way_cost) { WayCost.new departure: 'a', arrival: 'b' }

  describe '#evaluate' do

    it 'forwards uncompleted way cost to coster' do
      expect(coster).to receive(:evaluate).with([way_cost])
      expect(delegator_coster).to receive(:complete).with(way_cost).and_return false
      delegator_coster.evaluate [ way_cost ]
    end

    it "doesn't forward completed way cost to coster"  do
      expect(coster).to_not receive(:evaluate).with([way_cost])
      expect(delegator_coster).to receive(:complete).with(way_cost).and_return true
      delegator_coster.evaluate [ way_cost ]
    end

    it "mixes local and evaluated way_costs" do
      evaluated_way_cost = way_cost.dup.tap do |c|
        c.distance = 42
        c.time = 123
      end

      way_cost_2 = WayCost.new departure: 'b', arrival: 'c'
      local_way_cost = way_cost_2.dup.tap do |c|
        c.distance = 21
        c.time = 256
      end

      expect(delegator_coster).to receive(:complete).with(way_cost).and_return false
      expect(coster).to receive(:evaluate).with([way_cost]).and_return([evaluated_way_cost])

      expect(delegator_coster).to receive(:complete).with(way_cost_2) do |w|
        w.distance, w.time = local_way_cost.distance, local_way_cost.time
        true
      end

      expect(delegator_coster.evaluate([way_cost, way_cost_2])).to eq([local_way_cost, evaluated_way_cost])
    end

  end

  describe '#complete' do

    it 'returns false' do
      expect(delegator_coster.complete(way_cost)).to be_falsy
    end

  end

end
