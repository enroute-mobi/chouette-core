class ReferentialAudit
  class VehicleJourneyAtStopTimes < Base
    include ReferentialAudit::Concerns::VehicleJourneyBase

    def find_faulty
      Chouette::VehicleJourneyAtStop.where(departure_time: nil, arrival_time: nil).select('DISTINCT(vehicle_journey_id)')
    end

    def message(record, output: :console)
      "#{record_name(record, output)} has a stop with both times unset"
    end
  end
end
