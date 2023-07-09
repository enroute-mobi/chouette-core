class AddFareUrlToCompanies < ActiveRecord::Migration[5.2]
  on_public_schema_only do
    add_column :companies, :fare_url, :string
  end
end
