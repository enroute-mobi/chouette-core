# frozen_string_literal: true

module Scope
  module VehicleJourney
    class ByLines < Base
      def initialize(line_ids)
        super()
        @line_ids = line_ids
      end
      attr_reader :line_ids

      collection :vehicle_journeys do
        current_collection.with_lines(line_ids)
      end

      collection :metadatas do
        current_collection.with_lines(line_ids)
      end
    end
  end
end
