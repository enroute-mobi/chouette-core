class RemoveExportTypeFromPublicationSetups < ActiveRecord::Migration[5.2]
  def up
    on_public_schema_only do
      PublicationSetup.update_all("export_options = export_options || hstore('type', export_type)")

      remove_column :publication_setups, :export_type
    end
  end

  def down
    on_public_schema_only do
      add_column :publication_setups, :export_type, :string

      PublicationSetup.update_all("export_type = export_options -> 'type'")
    end
  end
end
