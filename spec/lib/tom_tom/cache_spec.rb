
RSpec.describe TomTom::Cache do

  let(:coster) { double }
  let(:backend_cache) { double read: nil, write: nil }
  subject(:cache_coster) { TomTom::Cache.new(coster) }

  before { allow(cache_coster).to receive(:cache).and_return(backend_cache) }

  let(:way_cost) { WayCost.new departure: "a", arrival: "b" }

  describe "#complete" do

    context "if the WayCost values are in the cache" do

      it "returns false" do
        cache_coster.complete way_cost
      end

    end

    context "if the WayCost values are in the cache" do

      let(:cached_values) { { distance: 42, time: 123 } }

      before do
        allow(backend_cache).to receive(:read).with(way_cost.cache_key).and_return cached_values
      end

      it "fills to the WayCost distance and time" do
        cache_coster.complete way_cost

        expect(way_cost.distance).to eq(cached_values[:distance])
        expect(way_cost.time).to eq(cached_values[:time])
      end

      it "returns true" do
        expect(cache_coster.complete(way_cost)).to be_truthy
      end

    end

  end

  describe "#after_coster" do

    context "if WayCost contains distance and time" do

      before do
        way_cost.distance = 42
        way_cost.time = 123
      end

      it "saves values in the cache" do
        expect(backend_cache).to receive(:write).with(way_cost.cache_key, { distance: way_cost.distance, time: way_cost.time }, expires_in: TomTom::Cache.default_ttl)
        cache_coster.after_coster(way_cost)
      end

    end

  end

end
