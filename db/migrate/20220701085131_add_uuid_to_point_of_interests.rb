class AddUuidToPointOfInterests < ActiveRecord::Migration[5.2]
  def change
    on_public_schema_only do
      add_column :point_of_interests, :uuid, :uuid, default: "gen_random_uuid()", null: false
    end
  end
end
