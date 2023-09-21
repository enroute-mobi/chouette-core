class AddNameToFareProviders < ActiveRecord::Migration[5.2]
  def change
    on_public_schema_only do
      add_column :fare_providers, :name, :string

      Fare::Provider.reset_column_information
      Fare::Provider.update_all(name: 'Default')

      change_column :fare_providers, :name, :string, null: false
    end
  end
end