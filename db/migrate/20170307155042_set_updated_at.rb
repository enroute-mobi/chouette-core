class SetUpdatedAt < ActiveRecord::Migration[4.2]
  def up
    models = %w(VehicleJourney TimeTable StopPoint StopArea RoutingConstraintZone Route Network Line
     JourneyPattern GroupOfLine ConnectionLink Company AccessPoint AccessLink)

    models.each do |table|
      "Chouette::#{table}".constantize.where(updated_at: nil).update_all('updated_at = created_at')
    end

  end

  def down
  end
end
