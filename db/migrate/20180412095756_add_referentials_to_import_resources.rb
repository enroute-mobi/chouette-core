class AddReferentialsToImportResources < ActiveRecord::Migration
  def change
    add_reference :import_resources, :referential, index: true, foreign_key: true
  end
end
