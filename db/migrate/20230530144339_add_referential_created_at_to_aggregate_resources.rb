class AddReferentialCreatedAtToAggregateResources < ActiveRecord::Migration[5.2]
  def change
    on_public_schema_only do
      add_column :aggregate_resources, :referential_created_at, :datetime
    end
  end
end
