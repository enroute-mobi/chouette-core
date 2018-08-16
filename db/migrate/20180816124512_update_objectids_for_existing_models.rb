class UpdateObjectidsForExistingModels < ActiveRecord::Migration
  def up
    collections = %w(time_tables purchase_windows routing_constraint_zones footnotes routes stop_points journey_patterns vehicle_journeys)

    Referential.where(objectid_format: 'stif_netex').find_each do |ref|
      collections.each do |collection|
        ref.send(collection).find_each { |obj| ref.objectid_formatter.after_commit(obj) }
      end
    end
  end
end
