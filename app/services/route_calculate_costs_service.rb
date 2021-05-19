class RouteCalculateCostsService

  def initialize(referential, update_journey_patterns: false)
    @referential, @update_journey_patterns = referential, update_journey_patterns
  end
  attr_accessor :referential, :update_journey_patterns
  alias update_journey_patterns? update_journey_patterns

  def update(route_or_route_id)
    return if disabled?

    route_id = route_or_route_id.respond_to?(:id) ? route_or_route_id.id : route_or_route_id
    RouteCalculateCostsJob.new(referential.id, route_id, update_journey_patterns: update_journey_patterns?).enqueue!
  end

  def update_all
    return if disabled?

    referential.switch
    Chouette::Benchmark.measure "route_calculate_costs", referential: referential.id do
      referential.routes.pluck(:id).each { |route_id| update route_id }
    end
  end

  def disabled?
    @disabled ||= referential.in_referential_suite? ||
                  !referential.organisation.has_feature?(:route_calculate_costs) ||
                  !referential.organisation.has_feature?(:costs_in_journey_patterns)
  end

end
