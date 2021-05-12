module RouteControl
  class StopPointsBoardingAndAlighting < ComplianceControl
    include RouteControl::InternalBaseInterface

    def self.default_code; "3-Route-12" end

    def self.compliance_test compliance_check, route
      route.stop_points.non_commercial.all? {|sp| sp.for_boarding == "forbidden" && sp.for_alighting == "forbidden" }
    end
  end
end
