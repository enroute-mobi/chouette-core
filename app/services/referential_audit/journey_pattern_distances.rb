class ReferentialAudit
  class JourneyPatternDistances < Base
    include ReferentialAudit::Concerns::JourneyPatternBase
    
    def message(record, output: :console)
      "#{record_name(record, output)} has negative distances"
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
