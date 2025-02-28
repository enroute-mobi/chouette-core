class CreateFlexibleAreaMemberships < ActiveRecord::Migration[5.2]
  def change
    on_public_schema_only do
      create_table :flexible_area_memberships do |t|
        t.references :flexible_area, null: false, foreign_key: { to_table: :stop_areas }
        t.references :member, null: false, foreign_key: { to_table: :stop_areas }
        t.timestamps
      end

      add_index :flexible_area_memberships, [:flexible_area_id, :member_id], unique: true, name: 'index_flexible_area_memberships_unique'
    end
  end
end
