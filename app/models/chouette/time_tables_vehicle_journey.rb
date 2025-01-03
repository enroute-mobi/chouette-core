module Chouette
  class TimeTablesVehicleJourney < Chouette::RelationshipRecord

    belongs_to :time_table # TODO: CHOUETTE-3247 optional: true?
    belongs_to :vehicle_journey # TODO: CHOUETTE-3247 optional: true?

  end
end
