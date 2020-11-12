module VehicleJourneyControl
  class Company < InternalBase
    def self.default_code; "3-VehicleJourney-11" end

    def self.compliance_test compliance_check, journey
      return true if journey.company_id.nil?
      return true if journey.route.line.company_id.nil?

      valid_ids = [journey.route.line.company_id]
      valid_ids +=  journey.route.line.secondary_company_ids
      valid_ids.map!(&:to_i)

      valid_ids.include? journey.company_id
    end
  end
end
