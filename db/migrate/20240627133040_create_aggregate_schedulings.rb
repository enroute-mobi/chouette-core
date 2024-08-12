# frozen_string_literal: true

class CreateAggregateSchedulings < ActiveRecord::Migration[5.2]
  def up # rubocop:disable Metrics/AbcSize,Metrics/MethodLength
    on_public_schema_only do
      create_table :aggregate_schedulings do |t|
        t.references :workgroup, null: false, foreign_key: true
        t.time :aggregate_time, null: false, default: '2000-01-01 00:00:00'
        t.bit :aggregate_days, null: false, limit: 7, default: '1111111'
        t.boolean :force_daily_publishing, null: false, default: true
        t.references :scheduled_job, foreign_key: { to_table: :delayed_jobs }
        t.timestamps null: false
      end

      Workgroup.where(nightly_aggregate_enabled: true).find_each do |workgroup|
        workgroup.aggregate_schedulings.create!(
          aggregate_time: TimeOfDay.create(workgroup.nightly_aggregate_time),
          aggregate_days: workgroup.nightly_aggregate_days,
          force_daily_publishing: true
        )
      end

      change_table :workgroups do |t|
        t.remove :nightly_aggregate_enabled
        t.remove :nightly_aggregate_time
        t.remove :nightly_aggregate_days
        t.remove :nightly_aggregated_at
      end

      Cron::BaseJob.schedule_all
    end
  end

  def down
    on_public_schema_only do
      change_table :workgroups do |t|
        t.boolean :nightly_aggregate_enabled
        t.time :nightly_aggregate_time, default: '2000-01-01 00:00:00'
        t.bit :nightly_aggregate_days, limit: 7, default: '1111111'
        t.datetime :nightly_aggregated_at
      end

      drop_table :aggregate_schedulings
    end
  end
end
