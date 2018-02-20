class CreateSimpleImporters < ActiveRecord::Migration
  def change
    create_table :simple_importers do |t|
      t.string :configuration_name
      t.string :filepath
      t.string :status
      t.json :journal
    end
  end
end
