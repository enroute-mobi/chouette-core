class AddCountryCodeToCompanies < ActiveRecord::Migration[5.2]
  def change
    on_public_schema_only do
      add_column :companies, :country_code, :string
    end
  end
end
