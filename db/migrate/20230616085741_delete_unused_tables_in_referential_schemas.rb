class DeleteUnusedTablesInReferentialSchemas < ActiveRecord::Migration[5.2]
  def up
    on_referential_schemas_only do
      ReferentialSchema.current.reduce_tables
    end
  end
end
