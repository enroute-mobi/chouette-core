class AddProcessedToExportables < ActiveRecord::Migration[5.2]
  def change
    on_public_schema_only do
      add_column :exportables, :processed, :boolean, default: false, null: false
    end
  end
end
