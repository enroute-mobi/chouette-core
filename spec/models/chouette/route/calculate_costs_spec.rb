
RSpec.describe Chouette::Route do

  subject(:route) { create(:route) }

  describe "#calculate_costs" do

    it 'creates WayCost from Route#stop_areas' do
      expect(WayCost).to receive(:from).with(route.stop_areas)

      route.calculate_costs
    end

    it 'evalues WayCosts with TomTom' do
      way_costs = [ WayCost.new(departure: 'a', arrival: 'b') ]
      allow(WayCost).to receive(:from).with(route.stop_areas).and_return way_costs

      expect(TomTom).to receive(:evaluate).with(way_costs).and_return way_costs

      route.calculate_costs
    end

    it 'saves costs Hash' do
      way_costs = [ WayCost.new(id: 'test', departure: 'a', arrival: 'b', distance: 42, time: 123) ]
      allow(TomTom).to receive(:evaluate).and_return way_costs

      route.calculate_costs

      expect(route.costs).to eq({ "test" => { 'distance' => 42, 'time' => 123 } })
    end
  end
end
