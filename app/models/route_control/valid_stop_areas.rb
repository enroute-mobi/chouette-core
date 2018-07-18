module RouteControl
  class ValidStopAreas < InternalControl::Base
    enumerize :criticity, in: %i(error), scope: true, default: :error

    def self.default_code; "3-Route-13" end

    def self.object_path compliance_check, route
      referential_line_route_path(route.referential, route.line, route)
    end

    def self.collection referential
      referential.routes
    end

    def self.compliance_test compliance_check, route
      valid_stop_areas = compliance_check.referential.workbench.stop_areas
      valid_stop_areas.where(id: route.stop_area_ids).count == route.stop_area_ids.size
    end

    def self.custom_message_attributes compliance_check, route
      {
        route_name: route.name,
        stop_area_ids: [].to_sentence,
        organisation_name: route.referential.workbench.organisation.name
      }
    end
  end
end
