class AddPostalRegionToPointOfInterest < ActiveRecord::Migration[5.2]
  def change
    on_public_schema_only do
      change_table :point_of_interests do |t|
        t.string :postal_region
      end
    end
  end
end
