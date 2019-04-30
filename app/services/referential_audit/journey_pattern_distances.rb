class ReferentialAudit
  class JourneyPatternDistances < Base

    def message(record, output: :console)
      record_name = "JourneyPattern ##{record.id}"
      if output == :html
        url = url_for([@referential, record.line, record.route, :journey_patterns_collection, host: base_host])
        record_name = link_to record_name, url
      end
      "#{record_name} has negative distances"
    end

    def find_faulty
      faulty = []
      Chouette::JourneyPattern.select(:id, :route_id, :costs).find_each do |jp|
        faulty << jp if jp.costs && jp.costs.any? {|k, v| v["distance"] && v["distance"].to_i < 0}
      end
      faulty
    end
  end
end
