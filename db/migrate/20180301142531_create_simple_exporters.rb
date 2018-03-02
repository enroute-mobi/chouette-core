class CreateSimpleExporters < ActiveRecord::Migration
  def change
    rename_table :simple_importers, :simple_interfaces
    add_column :simple_interfaces, :type, :string
    SimpleInterface.update_all type: :SimpleImporter
  end
end
