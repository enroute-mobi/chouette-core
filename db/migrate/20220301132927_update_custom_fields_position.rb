class UpdateCustomFieldsPosition < ActiveRecord::Migration[5.2]
  def change
     on_public_schema_only do
      Workgroup.find_each do |workgroup|
        workgroup.custom_fields.group_by{|i| [i[:workgroup_id], i[:resource_type]]}.each do |k, group|
          group.each_with_index do |custom_field, index|
            custom_field.update(position: index)
          end
        end
      end
    end
  end
end
