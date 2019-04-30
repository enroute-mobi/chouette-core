class ReferentialAudit
  class JourneyPatternStopPoints < Base

    def message(record, output: :console)
      record_name = "JourneyPattern ##{record.id}"
      if output == :html
        url = url_for([@referential, record.line, record.route, :journey_patterns_collection, host: base_host])
        record_name = link_to record_name, url
      end
      "#{record_name} has only #{record.stop_points.count} stop_point(s)"
    end

    def find_faulty
      Chouette::JourneyPattern.select('journey_patterns.id, COUNT(stop_points.id)').joins(:stop_points).group('journey_patterns.id').having('COUNT(stop_points.id) < 2')
    end
  end
end
