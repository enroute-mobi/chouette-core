class ReferentialAudit
  class VehicleJourneyInitialOffset < Base
    include ReferentialAudit::Concerns::VehicleJourneyBase
    
    def find_faulty
      Chouette::VehicleJourneyAtStop.where.not(departure_day_offset: 0).joins(:stop_point).where('stop_points.position' => 0)
    end

    def message(record, output: :console)
      "#{record_name(record, output)} has an initial offset > 0"
    end
  end
end
