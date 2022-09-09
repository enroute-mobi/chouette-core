class RemoveDelayedJobOperationType < ActiveRecord::Migration[5.2]
  def change
    on_public_schema_only do
      remove_column :delayed_jobs, :operation_type
    end
  end
end
