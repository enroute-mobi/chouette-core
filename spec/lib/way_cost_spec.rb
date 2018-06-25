RSpec.describe WayCost do
  describe "#calculate_distance" do
    it "calculates the distance between departure and arrival" do
      way_cost = WayCost.new(
        departure: Geokit::LatLng.new(48.85086, 2.36143),
        arrival: Geokit::LatLng.new(47.91231, 1.87606),
        distance: 1234,
        time: 99,
        id: '1-2'
      )

      expect(way_cost.calculate_distance).to eq(
        way_cost.departure.distance_to(way_cost.arrival, units: :kms) * 1000
      )
    end
  end
end
