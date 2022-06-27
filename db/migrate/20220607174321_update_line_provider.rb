class UpdateLineProvider < ActiveRecord::Migration[5.2]
  def change
    on_public_schema_only do
      add_column :line_providers, :name, :string

      LineProvider.reset_column_information
      LineProvider.where(name: nil).update_all("name = short_name")

      change_column_null :line_providers, :name, false
    end
  end
end
