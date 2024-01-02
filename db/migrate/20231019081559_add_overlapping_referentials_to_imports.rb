class AddOverlappingReferentialsToImports < ActiveRecord::Migration[5.2]
  def change
    on_public_schema_only do
      add_column :imports, :overlapping_referential_ids, :bigint, array: true, default: []
    end
  end
end
