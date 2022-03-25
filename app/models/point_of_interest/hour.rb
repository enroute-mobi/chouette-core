module PointOfInterest
  class Hour < ApplicationModel
    self.table_name = "point_of_interest_hours"

    def self.policy_class
      PointOfInterestPolicy
    end

  end
end
