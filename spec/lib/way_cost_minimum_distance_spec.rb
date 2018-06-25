RSpec.describe WayCostMinimumDistance do
  describe "#snap_short_costs_to_1" do
    let(:way_costs) do
      [
        # Paris–Bordeaux
        WayCost.new(
          departure: Geokit::LatLng.new(2.349, 48.85331),
          arrival: Geokit::LatLng.new(-0.57628, 44.84452)
        ),

        # Rue Poissonnière–Boulevard de Bonne Nouvelle
        WayCost.new(
          departure: Geokit::LatLng.new(2.34776, 48.86927),
          arrival: Geokit::LatLng.new(2.35, 48.8701)
        )
      ]
    end

    it "snaps distances under 500 metres to 1 kilometre" do
      unchanged, snapped = WayCostMinimumDistance.new(
        way_costs
      ).snap_short_costs_to_1

      expect(unchanged.distance).to eq(way_costs[0].distance)
      expect(snapped.distance).to eq(1000)
    end

    it "snaps time to 1 minute when distance is under 500 metres" do
      unchanged, snapped = WayCostMinimumDistance.new(
        way_costs
      ).snap_short_costs_to_1

      expect(unchanged.time).to eq(way_costs[0].time)
      expect(snapped.time).to eq(60)
    end
  end
end
