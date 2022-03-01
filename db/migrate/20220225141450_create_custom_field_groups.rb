class CreateCustomFieldGroups < ActiveRecord::Migration[5.2]
  def change
    on_public_schema_only do
      create_table :custom_field_groups do |t|
        t.references :workgroup

        t.string :name
        t.integer :position
        t.string :resource_type
        t.index [:workgroup_id, :resource_type, :position], unique: true, name: 'uniq_workgroup_id_and_resource_type_and_position'

        t.timestamps
      end
    end
  end
end
