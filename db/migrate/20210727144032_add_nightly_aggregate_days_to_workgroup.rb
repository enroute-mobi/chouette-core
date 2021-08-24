class AddNightlyAggregateDaysToWorkgroup < ActiveRecord::Migration[5.2]
  def change
    on_public_schema_only do
      add_column :workgroups, :nightly_aggregate_days, 'bit(7)', default: '1111111'
    end
  end
end
