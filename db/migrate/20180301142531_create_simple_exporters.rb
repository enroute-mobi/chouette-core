class CreateSimpleExporters < ActiveRecord::Migration[4.2]
  def change
    rename_table :simple_importers, :simple_interfaces
    add_column :simple_interfaces, :type, :string

    class_exist = begin
      SimpleInterface.is_a?(Class)
    rescue NameError
      false
    end

    SimpleInterface.update_all type: :SimpleImporter if class_exist
  end
end
