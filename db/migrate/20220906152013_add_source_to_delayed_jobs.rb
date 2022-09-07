class AddSourceToDelayedJobs < ActiveRecord::Migration[5.2]
  def change
    on_public_schema_only do
      add_reference :delayed_jobs, :source, foreign_key: true
    end
  end
end
