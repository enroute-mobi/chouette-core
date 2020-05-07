class AddDefaultLanguageToCompany < ActiveRecord::Migration[5.2]
  def change
  	add_column :companies, :default_language, :string
  end
end
