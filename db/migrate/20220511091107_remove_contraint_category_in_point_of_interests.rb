class RemoveContraintCategoryInPointOfInterests < ActiveRecord::Migration[5.2]
  def change
    on_public_schema_only do
      change_column :point_of_interests, :point_of_interest_category_id, :bigint, null: true
    end
  end
end
