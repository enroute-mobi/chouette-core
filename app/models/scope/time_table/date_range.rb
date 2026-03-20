# frozen_string_literal: true

module Scope
  module TimeTable
    class DateRange < Base
      def initialize(date_range)
        super()
        @date_range = date_range
      end
      attr_reader :date_range

      collection :time_tables do
        current_collection.applied_at_least_once_in(date_range)
      end

      collection :vehicle_journeys do
        current_collection.with_matching_timetable(date_range)
      end

      collection :metadatas do
        current_collection.include_daterange(date_range)
      end

      attribute :validity_period do
        current_value & date_range
      end
    end
  end
end
