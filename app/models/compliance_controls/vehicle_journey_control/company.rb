module VehicleJourneyControl
  class Company < InternalBase
    def self.default_code; "3-VehicleJourney-11" end

    def self.compliance_test compliance_check, journey
      journey.company_id == compliance_check.control_attributes['company_id'].to_i
    end
  end
end
