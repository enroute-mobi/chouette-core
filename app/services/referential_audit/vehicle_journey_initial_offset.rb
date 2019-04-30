class ReferentialAudit
  class VehicleJourneyInitialOffset < Base
    def find_faulty
      Chouette::VehicleJourneyAtStop.where.not(departure_day_offset: 0).joins(:stop_point).where('stop_points.position' => 0)
    end

    def message(record, output: :console)
      vj = record.vehicle_journey
      record_name = "VehicleJourney ##{record.vehicle_journey_id}"
      if output == :html
        url = url_for([@referential, vj.line, vj.route, :vehicle_journeys, host: base_host])
        record_name = link_to record_name, url
      end
      "#{record_name} has an initial offset > 0"
    end
  end
end
