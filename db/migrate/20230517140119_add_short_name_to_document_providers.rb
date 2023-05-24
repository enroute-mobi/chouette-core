class AddShortNameToDocumentProviders < ActiveRecord::Migration[5.2]
  def change
    on_public_schema_only do
      add_column :document_providers, :short_name, :string

      DocumentProvider.reset_column_information
      DocumentProvider.update_all('short_name = name')

      change_column :document_providers, :short_name, :string, null: false
    end
  end
end
