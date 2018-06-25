class RouteWayCostCalculator
  def initialize(route)
    @route = route
  end

  def calculate!
    way_costs = StopAreasToWayCostsConverter.new(@route.stop_areas).convert
    way_costs = TomTom.matrix(way_costs)
    way_costs = WayCostMinimumDistance.new(way_costs).snap_short_costs_to_1
    way_costs = WayCostCollectionJSONSerializer.dump(way_costs)
    @route.update(costs: way_costs)
  rescue TomTom::Errors::MatrixRemoteError => e
    Rails.logger.error "TomTom::Matrix server error: #{e}"
  end
end
