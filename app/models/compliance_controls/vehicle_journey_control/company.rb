module VehicleJourneyControl
  class Company < InternalBase
    def self.default_code; '3-VehicleJourney-11' end

    def self.collection(compliance_check)
      super.joins(:route).select('*','routes.line_id as line_id')
    end

    class Control
      def initialize(_, compliance_check)
        @compliance_check = compliance_check
      end

      attr_reader :compliance_check

      def tested_line(line_id)
        @tested_line ||= @compliance_check.referential.lines.find(line_id)
      end

      def tested_line_companies(line_id)
        @tested_line_companies ||= @compliance_check.referential.lines.find(line_id).company_ids
      end

      def compliance_test(_, journey)
        return true if journey.company_id.nil? || tested_line(journey.line_id).company_id.nil?

        tested_line_companies(journey.line_id).include? journey.company_id
      end
    end
  end
end
