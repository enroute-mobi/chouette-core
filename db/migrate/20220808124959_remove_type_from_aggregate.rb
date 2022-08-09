class RemoveTypeFromAggregate < ActiveRecord::Migration[5.2]
  def change
    on_public_schema_only do
      remove_column :aggregates, :type
    end
  end
end
