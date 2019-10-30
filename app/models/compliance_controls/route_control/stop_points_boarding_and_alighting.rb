require_dependency 'compliance_controls/route_control/internal_base'

module RouteControl
  class StopPointsBoardingAndAlighting < InternalBase

    def self.default_code; "3-Route-12" end

    def self.compliance_test compliance_check, route
      route.stop_points.non_commercial.all? {|sp| sp.for_boarding == "forbidden" && sp.for_alighting == "forbidden" }
    end
  end
end
