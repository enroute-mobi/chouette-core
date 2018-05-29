class SetUpdatedAt < ActiveRecord::Migration
  def up
    models = %w(VehicleJourney TimeTable StopPoint StopArea RoutingConstraintZone Route PtLink Network Line
     JourneyPattern GroupOfLine Company)

    models.each do |table|
      "Chouette::#{table}".constantize.where(updated_at: nil).update_all('updated_at = created_at')
    end

  end

  def down
  end
end
