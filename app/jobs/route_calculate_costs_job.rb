class RouteCalculateCostsJob

  def initialize(referential_id, route_id, options = {})
    @referential_id, @route_id = referential_id, route_id
    options.each { |k,v| send "#{k}=", v }
  end

  attr_accessor :referential_id, :route_id, :update_journey_patterns
  alias update_journey_patterns? update_journey_patterns

  def referential
    Referential.find referential_id
  end

  def route
    referential.routes.find route_id
  end

  def perform
    return unless TomTom.enabled?

    begin
      referential.switch
      CustomFieldsSupport.within_workgroup(referential.workgroup) do
        route.calculate_costs

        if update_journey_patterns?
          route.journey_patterns.each(&:use_default_costs!)
        end
      end
    rescue => e
      Chouette::Safe.capture "#{self.class.name} referential #{referential_id}/route #{route_id} failed", e
      raise e
    end
  end

  def max_attempts
    3
  end

  def enqueue!
    Delayed::Job.enqueue self
  end

end
