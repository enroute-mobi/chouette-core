# frozen_string_literal: true

module Chouette
  class JourneyPatternStopPoint < Chouette::RelationshipRecord
    self.table_name = :journey_patterns_stop_points

    belongs_to :journey_pattern
    belongs_to :stop_point
  end
end
