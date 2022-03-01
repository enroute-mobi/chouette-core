class AddPositionToCustomFields < ActiveRecord::Migration[5.2]
  def change
    on_public_schema_only do
      add_column :custom_fields, :position, :integer
      add_reference :custom_fields, :custom_field_group, foreign_key: true
      add_index :custom_fields, [:custom_field_group_id, :position], :unique => true, name: 'uniq_custom_field_group_id_and_position'
    end
  end
end
