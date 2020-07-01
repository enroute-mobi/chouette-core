module Chouette
  class VehicleJourneyFootnoteRelationship < RelationshipRecord
    self.table_name = "footnotes_vehicle_journeys"

    belongs_to :footnote
    belongs_to :vehicle_journey
  end
end
