# frozen_string_literal: true

class AddScheduledColumnsToProcessingRules < ActiveRecord::Migration[7.2]
  def change
    on_public_schema_only do
      change_table :processing_rules do |t|
        t.time :scheduling_time, null: false, default: '2000-01-01 00:00:00'
        t.bit :scheduling_days, null: false, limit: 7, default: '1111111'
        t.string :scheduling_target, null: false, default: 'none'
        t.references :scheduled_job, foreign_key: { to_table: :delayed_jobs }
      end
    end
  end
end
