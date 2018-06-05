module VehicleJourneyControl
  class BusCapacity < InternalBase
    def self.default_code; "3-VehicleJourney-9" end

    def self.compliance_test compliance_check, vehicle_journey
      vehicle_journey.custom_fields[:capacity]&.value.present?
    end
  end
end
