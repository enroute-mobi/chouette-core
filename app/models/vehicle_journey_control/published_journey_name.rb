module VehicleJourneyControl
  class PublishedJourneyName < ComplianceControl
    store_accessor :control_attributes, :minimum, :maximum, :company_id
    validates_presence_of :company_id

    include MinMaxValuesValidation

    def self.default_code; "3-VehicleJourney-8" end

    def self.object_path compliance_check, vj
      referential_line_route_vehicle_journeys_collection_path(vj.referential, vj.line, vj.route)
    end

    def self.collection referential
      referential.vehicle_journeys
    end

    def self.compliance_test compliance_check, vj
      vj&.published_journey_name&.to_i.between?(compliance_check.minimum.to_i, compliance_check.maximum.to_i)
    end

    def self.custom_message_attributes compliance_check, vj
      {
        source_objectid: vj.objectid,
        min: compliance_check.minimum,
        max: compliance_check.maximum,
        company_name: Chouette::Company.find(compliance_check.company_id).name
        }
    end
  end
end
