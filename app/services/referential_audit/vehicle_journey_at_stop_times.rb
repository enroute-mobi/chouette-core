class ReferentialAudit
  class VehicleJourneyAtStopTimes < Base
    def find_faulty
      Chouette::VehicleJourneyAtStop.where(departure_time: nil, arrival_time: nil).select('DISTINCT(vehicle_journey_id)')
    end

    def message(record, output: :console)
      vj = record.vehicle_journey
      record_name = "VehicleJourney ##{record.vehicle_journey_id}"
      if output == :html
        url = url_for([@referential, vj.line, vj.route, :vehicle_journeys, host: base_host])
        record_name = link_to record_name, url
      end
      "#{record_name} has a stop with both times unset"
    end
  end
end
