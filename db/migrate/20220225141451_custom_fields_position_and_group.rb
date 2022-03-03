class CustomFieldsPositionAndGroup < ActiveRecord::Migration[5.2]
  def change
    on_public_schema_only do
      create_table :custom_field_groups do |t|
        t.references :workgroup

        t.string :name
        t.integer :position
        t.string :resource_type
        t.index [ :workgroup_id, :resource_type, :position ], unique: true, name: 'uniq_workgroup_id_and_resource_type_and_position'

        t.timestamps
      end

      add_column :custom_fields, :position, :integer
      add_reference :custom_fields, :custom_field_group, foreign_key: true

      CustomField.reset_column_information
      Workgroup.includes(:custom_fields).find_each do |workgroup|
        workgroup.custom_fields.group_by(&:resource_type).each do |_, custom_fields|
          custom_fields.each_with_index do |custom_field, index|
            custom_field.update position: index
          end
        end
      end

      change_column_null :custom_fields, :position, false
      add_index :custom_fields, [:workgroup_id, :resource_type, :custom_field_group_id, :position], :unique => true, name: 'uniq_workgroup_id_resource_type_custom_field_group_id_position'
    end
  end
end
