class Chouette::JourneyPatternsStopPoint < ActiveRecord::Base
  belongs_to :journey_pattern
  belongs_to :stop_point
end
