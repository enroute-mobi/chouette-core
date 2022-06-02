module RouteControl
  class StopAreaTypes < ComplianceControl
    include RouteControl::InternalBaseInterface

    def self.default_code; "3-Route-14" end

    def self.compliance_test _compliance_check, route
      route.stop_areas.where.not(area_type: route.referential.stop_area_referential.available_stops).length == 0
    end

    def self.custom_message_attributes _compliance_check, route
      invalid_stop_areas = route.stop_areas.where.not(area_type: route.referential.stop_area_referential.available_stops)
      {
        route_name: route.name,
        stop_area_names: invalid_stop_areas.pluck(:name).to_sentence,
        stop_area_types: invalid_stop_areas.pluck(:area_type).map{ |s| I18n.t("area_types.label.#{s}") }.to_sentence,
        permitted_types: route.referential.stop_area_referential.available_stops.map{|s| I18n.t("area_types.label.#{s}") }.to_sentence,
        organisation_name: route.referential.workbench.name
      }
    end
  end
end
