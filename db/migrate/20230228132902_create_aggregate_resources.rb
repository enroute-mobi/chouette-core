class CreateAggregateResources < ActiveRecord::Migration[5.2]
  def change
    on_public_schema_only do
      create_table :aggregate_resources do |t|
        t.string :workbench_name
        t.integer :position
        t.integer :priority
        t.integer :duration
        t.jsonb :metrics
        t.string :referential_name
        t.references :aggregate
      end
    end
  end
end
