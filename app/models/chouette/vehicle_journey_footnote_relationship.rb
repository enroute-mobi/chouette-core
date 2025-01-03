module Chouette
  class VehicleJourneyFootnoteRelationship < RelationshipRecord
    self.table_name = "footnotes_vehicle_journeys"

    belongs_to :footnote # TODO: CHOUETTE-3247 optional: true?
    belongs_to :vehicle_journey # TODO: CHOUETTE-3247 optional: true?
  end
end
