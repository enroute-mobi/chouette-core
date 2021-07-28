class AddNightlyAggregateDaysToWorkgroup < ActiveRecord::Migration[5.2]
  def change
    on_public_schema_only do
      add_column :workgroups, :nightly_aggregate_days, :string, default: [], array: true
    end
  end
end
