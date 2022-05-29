module RouteControl
  class ValidStopAreas < ComplianceControl
    include RouteControl::InternalBaseInterface

    def self.default_code; "3-Route-13" end

    def self.compliance_test compliance_check, route
      valid_stop_areas = compliance_check.referential.workbench.stop_areas
      valid_stop_areas.where(id: route.stop_area_ids).count == route.stop_area_ids.size
    end

    def self.custom_message_attributes compliance_check, route
      invalid_stop_areas = route.stop_areas.where.not(id: compliance_check.referential.workbench.stop_areas.pluck(:id))
      {
        route_name: route.name,
        stop_area_ids: invalid_stop_areas.pluck(:name).to_sentence,
        organisation_name: route.referential.workbench.name
      }
    end
  end
end
