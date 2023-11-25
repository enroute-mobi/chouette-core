class Chouette::JourneyPatternsStopPoint < ActiveRecord::Base
  acts_as_copy_target

  belongs_to :journey_pattern
  belongs_to :stop_point
end
