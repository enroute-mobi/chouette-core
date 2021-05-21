class RemoveExportTypeFromPublicationSetups < ActiveRecord::Migration[5.2]
  def up
    on_public_schema_only do
      ActiveRecord::Base.transaction do
        PublicationSetup.select(:export_type).update_all("export_options = export_options || 'type => export_type' ")
      end

      remove_column :publication_setups, :export_type
    end
  end

  def down
    on_public_schema_only do
      add_column :publication_setups, :export_type, :string

      ActiveRecord::Base.transaction do
        PublicationSetup.select("export_options -> 'type' AS type").update_all("SET export_type = type")
      end
    end
  end
end
