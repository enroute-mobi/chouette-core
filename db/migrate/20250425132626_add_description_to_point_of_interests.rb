class AddDescriptionToPointOfInterests < ActiveRecord::Migration[6.1]
  def change
    on_public_schema_only do
      change_table :point_of_interests do |t|
        t.text :description
      end
    end
  end
end
