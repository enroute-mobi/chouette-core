# frozen_string_literal: true

module Chouette
  class JourneyPatternStopPoint < Chouette::RelationshipRecord
    self.table_name = :journey_patterns_stop_points

    belongs_to :journey_pattern # TODO: CHOUETTE-3247 optional: true?
    belongs_to :stop_point # TODO: CHOUETTE-3247 optional: true?
  end
end
