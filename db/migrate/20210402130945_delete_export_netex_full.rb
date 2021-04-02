class DeleteExportNetexFull < ActiveRecord::Migration[5.2]
  def change
    on_public_schema_only do
      Export::NetexFull.destroy_all
    end
  end
end
