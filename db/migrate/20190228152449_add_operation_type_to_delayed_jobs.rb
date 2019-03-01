class AddOperationTypeToDelayedJobs < ActiveRecord::Migration
  def change
    add_column :delayed_jobs, :operation_type, :string
  end
end
