module RouteControl
  class StopPointsBoardingAndAlighting < InternalControl::Base
    def self.default_code; "3-Route-12" end

    def self.object_path compliance_check, route
      referential_line_route_path(route.referential, route.line, route)
    end

    def self.collection referential
      Chouette::Route.where id: referential.routes.pluck(:id)
    end

    def self.compliance_test compliance_check, route
      route.stop_points.commercial.all? {|sp| sp.for_boarding == "forbidden" && sp.for_alighting == "forbidden" }
    end

    def self.custom_message_attributes compliance_check, route
      {source_objectid: route.objectid}
    end
  end
end
