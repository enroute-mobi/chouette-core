class RouteWayCostUnitConverter
  def self.convert(way_costs)
    return if way_costs.nil?

    way_costs.each do |_, costs|
      costs['distance'] = self.meters_to_kilometers(costs['distance'])
      costs['time'] = self.seconds_to_minutes(costs['time'])
    end
  end

  def self.meters_to_kilometers(num)
    return 0 unless num

    snap_to_one(num / 1000.0).to_i
  end

  def self.seconds_to_minutes(num)
    return 0 unless num

    snap_to_one(num / 60.0).to_i
  end

  private

  def self.snap_to_one(decimal)
    return 1 if decimal > 0 && decimal <= 1

    decimal
  end
end
