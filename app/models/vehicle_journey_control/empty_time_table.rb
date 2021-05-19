module VehicleJourneyControl
  class EmptyTimeTable < ComplianceControl
    include VehicleJourneyControl::InternalBaseInterface

    def self.default_code; "3-VehicleJourney-10" end

    def self.collection(compliance_check)
      super.includes(:time_tables)
    end

    def self.compliance_test compliance_check, vehicle_journey
      !vehicle_journey.time_tables.empty.exists?
    end

    def self.custom_message_attributes compliance_check, vj
      {
        source_objectid: vj.objectid,
        vj_name: vj.published_journey_name,
        tt_names: vj.time_tables.empty.pluck(:comment).to_sentence
        }
    end
  end
end
