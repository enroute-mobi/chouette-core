# frozen_string_literal: true

module Chouette
  class TimeTablesVehicleJourney < Chouette::RelationshipRecord
    belongs_to :time_table, skippable: true
    belongs_to :vehicle_journey
  end
end
