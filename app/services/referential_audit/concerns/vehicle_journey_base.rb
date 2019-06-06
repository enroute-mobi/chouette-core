module ReferentialAudit::Concerns::VehicleJourneyBase
  def record_name(record, output)
    vj = record.vehicle_journey
    record_name = "VehicleJourney ##{record.vehicle_journey_id}"
    if output == :html
      url = url_for([@referential, vj.line, vj.route, :vehicle_journeys, host: base_host])
      record_name = link_to record_name, url
    end
    record_name
  end
end
