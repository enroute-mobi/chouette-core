module VehicleJourneyControl
  class Company < InternalBase
    def self.default_code; "3-VehicleJourney-11" end

    def self.compliance_test _, journey
      tested_line = journey.line
      return true if journey.company_id.nil? || tested_line.company_id.nil?

      valid_ids = [tested_line.company_id]
      valid_ids += tested_line.secondary_company_ids
      valid_ids.map!(&:to_i)

      valid_ids.include? journey.company_id
    end
  end
end
