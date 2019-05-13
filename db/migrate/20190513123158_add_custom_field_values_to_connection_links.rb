class AddCustomFieldValuesToConnectionLinks < ActiveRecord::Migration[5.2]
  def change
    add_column :connection_links, :custom_field_values, :jsonb, default: {}
  end
end
