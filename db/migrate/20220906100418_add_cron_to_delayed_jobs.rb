class AddCronToDelayedJobs < ActiveRecord::Migration[5.2]
  def self.up
    on_public_schema_only do
      add_column :delayed_jobs, :cron, :string
      add_column :sources, :retrieval_time_of_day, :time
      add_reference :sources, :scheduled_job

      Source.reset_column_information
      Source.enabled.update_all(retrieval_time_of_day: TimeOfDay.new(0, 0))
      Source.find_each(&:reschedule!)
    end
  end

  def self.down
    on_public_schema_only do
      remove_column :delayed_jobs, :cron
      remove_column :sources, :retrieval_time_of_day
      remove_reference :sources, :scheduled_job
    end
  end
end