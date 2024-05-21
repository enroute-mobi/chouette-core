class RemoveNetexExportTypes < ActiveRecord::Migration[5.2]
  def change
    on_public_schema_only do
      Workgroup
        .where("'Export::Netex' = ANY (export_types)")
        .update_all("export_types = array_remove(export_types, 'Export::Netex')")
    end
  end
end
