class ReferentialAudit
  class JourneyPatternDistances < Base

    def message
      "Found #{faulty.size - 1} JourneyPattern with negative distances"
    end

    def find_faulty
      faulty = []
      Chouette::JourneyPattern.find_each do |jp|
        faulty << jp if jp.costs && jp.costs.any? {|k, v| v["distance"] && v["distance"].to_i < 0}
      end
      faulty
    end
  end
end
