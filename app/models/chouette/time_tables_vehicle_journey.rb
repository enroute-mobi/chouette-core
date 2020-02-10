module Chouette
  class TimeTablesVehicleJourney < Chouette::RelationshipRecord

    belongs_to :time_table
    belongs_to :vehicle_journey

  end
end
