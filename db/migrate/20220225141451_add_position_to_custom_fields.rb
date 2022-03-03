class AddPositionToCustomFields < ActiveRecord::Migration[5.2]
  def change
    on_public_schema_only do
      add_column :custom_fields, :position, :integer
      CustomField.reset_column_information
      Workgroup.includes(:custom_fields).find_each do |workgroup|
        workgroup.custom_fields.group_by{|i| i[:resource_type]]}.each do |k, group|
          group.each_with_index do |custom_field, index|
            custom_field.update(position: index)
          end
        end
      end
      add_reference :custom_fields, :custom_field_group, foreign_key: true
      add_index :custom_fields, [:workgroup_id, :resource_type, :custom_field_group_id, :position], :unique => true, name: 'uniq_workgroup_id_resource_type_custom_field_group_id_position'
      change_column_null(:custom_fields, :position, false)
    end
  end
end
