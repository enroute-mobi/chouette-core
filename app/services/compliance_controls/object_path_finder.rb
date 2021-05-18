module ComplianceControls
  class ObjectPathFinder < ApplicationService
    include Rails.application.routes.url_helpers

    attr_reader :compliance_check, :object

    def initialize compliance_check, object
      @compliance_check = compliance_check
      @object = object
    end

    def call
      case object.class.name
        when 'Chouette::Company' then workbench_line_referential_company_path(compliance_check.compliance_check_set.workbench, object)
        when 'Chouette::Footnote' then referential_line_footnote_path(compliance_check.referential, object.line, object)
        when 'Chouette::JourneyPattern' then referential_line_route_journey_patterns_collection_path(object.referential, object.route.line, object.route)
        when 'Chouette::Line' then referential_line_path(compliance_check.referential, object)
        when 'Chouette::Route' then  referential_line_route_path(object.referential, object.line, object)
        when 'Chouette::RoutingConstraintZone' then referential_line_routing_constraint_zone_path(object.referential, object.route.line, object)
        when 'Chouette::StopArea' then workbench_stop_area_referential_stop_area_path(compliance_check.compliance_check_set.workbench, object)
        when 'Chouette::VehicleJourney' then referential_line_route_vehicle_journeys_path(compliance_check.referential, object.route.line, object.route)
        else
          raise "object class not supported: #{object.class}"
        end
    end
  end
end