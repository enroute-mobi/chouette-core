module VehicleJourneyControl
  class PublishedJourneyName < ComplianceControl
    store_accessor :control_attributes, :minimum, :maximum, :company_id
    validates_presence_of :company_id

    include MinMaxValuesValidation
    include VehicleJourneyControl::InternalBaseInterface

    def self.default_code; "3-VehicleJourney-8" end

    def self.compliance_test compliance_check, vj
      if vj.company_id == compliance_check.control_attributes['company_id'].to_i
        vj&.published_journey_name&.to_i.between?(compliance_check.control_attributes["minimum"].to_i, compliance_check.control_attributes["maximum"].to_i)
      else
        true
      end
    end

    def self.custom_message_attributes compliance_check, vj
      {
        source_objectid: vj.objectid,
        min: compliance_check.control_attributes["minimum"],
        max: compliance_check.control_attributes["maximum"],
        company_name: Chouette::Company.find(compliance_check.control_attributes["company_id"]).name
        }
    end
  end
end
