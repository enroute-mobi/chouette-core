class AddDefaultLanguageToCompany < ActiveRecord::Migration[5.2]
  def change
    on_public_schema_only do
  	  add_column :companies, :default_language, :string
    end
  end
end
