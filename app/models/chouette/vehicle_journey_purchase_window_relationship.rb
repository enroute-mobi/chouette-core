module Chouette
  class VehicleJourneyPurchaseWindowRelationship < RelationshipRecord
    self.table_name = "purchase_windows_vehicle_journeys"

    belongs_to :purchase_window
    belongs_to :vehicle_journey

  end
end
