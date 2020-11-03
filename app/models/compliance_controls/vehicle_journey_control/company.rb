module VehicleJourneyControl
  class Company < InternalBase
    def self.default_code; "3-VehicleJourney-11" end

    def self.compliance_test compliance_check, journey
      valid_ids = [compliance_check.control_attributes['company_id']]
      valid_ids +=  compliance_check.control_attributes['secondary_company_ids']
      valid_ids.map!(&:to_i)

      valid_ids.include? journey.company_id
    end
  end
end
