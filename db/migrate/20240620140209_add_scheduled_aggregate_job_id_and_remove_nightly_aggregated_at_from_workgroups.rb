# frozen_string_literal: true

class AddScheduledAggregateJobIdAndRemoveNightlyAggregatedAtFromWorkgroups < ActiveRecord::Migration[5.2]
  def up
    on_public_schema_only do
      change_table :workgroups do |t|
        t.references :scheduled_aggregate_job, foreign_key: { to_table: :delayed_jobs }
        t.remove :nightly_aggregated_at
      end

      Cron::BaseJob.schedule_all
      Workgroup.where(nightly_aggregate_enabled: true).find_each(&:reschedule_aggregate)
    end
  end

  def down
    on_public_schema_only do
      change_table :workgroups do |t|
        t.datetime :nightly_aggregated_at
      end
      remove_reference :workgroups, :scheduled_aggregate_job
    end
  end
end
