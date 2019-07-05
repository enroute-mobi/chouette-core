class ReferentialAudit
  class JourneyPatternStopPoints < Base
    include ReferentialAudit::Concerns::JourneyPatternBase

    def message(record, output: :console)
      "#{record_name(record, output)} has only #{record.stop_points.count} stop_point(s)"
    end

    def find_faulty
      Chouette::JourneyPattern.select('journey_patterns.id, journey_patterns.route_id, COUNT(stop_points.id)').joins(:stop_points).group('journey_patterns.id').having('COUNT(stop_points.id) < 2')
    end
  end
end
