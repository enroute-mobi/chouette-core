class AddCountryCodeToCompanies < ActiveRecord::Migration[5.2]
  def change
    add_column :companies, :country_code, :string
  end
end
