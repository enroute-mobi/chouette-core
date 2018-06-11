module VehicleJourneyControl
  class PurchaseWindowDates < InternalControl::Base
    def self.default_code; "3-VehicleJourney-7" end

    def self.object_path compliance_check, vehicle_journey
      referential_line_route_vehicle_journeys_collection_path(compliance_check.referential, vehicle_journey.route.line, vehicle_journey.route)
    end

    def self.collection referential
      referential.vehicle_journeys.joins(:time_tables, :purchase_windows)
    end

    def self.compliance_test compliance_check, vehicle_journey
      vehicle_journey.selling_bounding_dates.last <= vehicle_journey.bounding_dates.last
    end

    def self.custom_message_attributes compliance_check, vehicle_journey
      {source_objectid: vehicle_journey.objectid}
    end
  end
end
