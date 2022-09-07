class AddCronToDelayedJobs < ActiveRecord::Migration[5.2]
  def self.up
    on_public_schema_only do
      add_column :delayed_jobs, :cron, :string
    end
  end

  def self.down
    on_public_schema_only do
      remove_column :delayed_jobs, :cron
    end
  end
end
