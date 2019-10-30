require_dependency 'compliance_controls/vehicle_journey_control/internal_base'

module VehicleJourneyControl
  class BusCapacity < InternalBase
    only_with_custom_field Chouette::VehicleJourney, :capacity

    def self.default_code; "3-VehicleJourney-9" end

    def self.compliance_test compliance_check, vehicle_journey
      vehicle_journey.custom_fields[:capacity]&.display_value.present?
    end
  end
end
