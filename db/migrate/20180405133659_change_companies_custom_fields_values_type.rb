class ChangeCompaniesCustomFieldsValuesType < ActiveRecord::Migration[4.2]
  def change
    reversible do |dir|
      dir.up { change_column :companies, :custom_field_values, 'jsonb', using: 'custom_field_values::jsonb', :default => {} }
      dir.down { change_column :companies, :custom_field_values, 'json', using: 'custom_field_values::json', :default => {} }
    end
  end
end
