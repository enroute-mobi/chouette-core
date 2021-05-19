module CustomFieldControl
  class Presence < ComplianceControl
    include ComplianceControls::InternalControlInterface
    only_if ->(organisation) { !organisation.custom_fields.empty? }

    store_accessor :control_attributes, :custom_field_code

    def self.default_code; "3-Generic-4" end

    def self.object_path compliance_check, object
      case custom_field(compliance_check).resource_type
      when "Company"
        redirect_company_path object
      when "VehicleJourney"
        polymorphic_path [object.referential, object.route.line, object.route, :vehicle_journeys]
      when "JourneyPattern"
        polymorphic_path [object.referential, object.route.line, object.route, :journey_patterns_collection]
      when "StopArea"
        polymorphic_path [object.stop_area_referential, object]
      else
        polymorphic_path [compliance_check.referential]
      end
    end

    def self.collection_type(compliance_check)
      custom_field = custom_field(compliance_check)
      custom_field.resource_type.tableize
    end

    def self.lines_for(compliance_check, object)
      referential_lines = compliance_check.referential.lines

      case custom_field(compliance_check).resource_type
      when "Company"
        referential_lines.where(company_id: object.id)
      when "VehicleJourney", "JourneyPattern"
        [object.route.line]
      when "StopArea"
        compliance_check.referential.stop_points.where(stop_area_id: object.id).map(&:line).uniq
      else
        [object.line]
      end
    end

    def self.compliance_test compliance_check, object
      object.custom_fields[compliance_check.control_attributes["custom_field_code"]]&.display_value.present?
    end

    def self.custom_message_attributes compliance_check, object
      super.update(field_name: custom_field(compliance_check).name)
    end

    def self.custom_field compliance_check
      CustomField.find_by code: compliance_check.control_attributes["custom_field_code"]
    end

    def self.label_attr(compliance_check)
      case custom_field(compliance_check).resource_type
      when "VehicleJourney"
        :published_journey_name
      else
        super
      end
    end
  end
end
