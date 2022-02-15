class AddColumnsToEntrances < ActiveRecord::Migration[5.2]
  def change
    on_public_schema_only do
      add_column :entrances,:external_flag, :bool
      add_column :entrances, :width, :float
      add_column :entrances, :height, :float
      add_column :entrances, :import_xml, :text
    end
  end
end
