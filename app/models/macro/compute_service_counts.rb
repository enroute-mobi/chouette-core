# frozen_string_literal: true

module Macro
  class ComputeServiceCounts < Macro::Base
    class Run < Macro::Base::Run
      def run
        lines.find_each { |line| create_message(line) }
      end

      # Create a message for the given line from Service Counts
      def create_message(line)
        attributes = {
          message_attributes: { name: line.name },
          source: line
        }

        macro_messages.create!(attributes)
      end

      private

      def lines
        @lines ||= referential.lines.where(id: service_counts.select(:line_id).distinct)
      end

      def service_counts
        @service_counts ||= begin
          referential.service_counts.compute_for_referential(referential)
          referential.service_counts
        end
      end
    end
  end
end
