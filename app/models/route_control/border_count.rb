module RouteControl
  class BorderCount < InternalBase
    required_features :core_controls

    def self.default_code; "3-Route-11" end

    def self.compliance_test compliance_check, route
      country_changes = route.stop_areas.pluck(:country_code).compact.chunk(&:itself).map(&:first).count - 1
      route.stop_areas.where(area_type: :border).count == country_changes * 2
    end
  end
end
