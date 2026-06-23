# frozen_string_literal: true

class CreateProcessingRuleSchedulings < ActiveRecord::Migration[7.2]
  def up
    on_public_schema_only do
      create_table :processing_rule_schedulings do |t|
        t.references :processing_rule, null: false, foreign_key: true
        t.time :scheduled_time, null: false, default: '2000-01-01 00:00:00'
        t.bit :scheduled_days, null: false, limit: 7, default: '1111111'
        t.string :target, null: false, default: 'none'
        t.references :scheduled_job, foreign_key: { to_table: :delayed_jobs }
        t.timestamps null: false
      end
    end
  end

  def down
    on_public_schema_only do
      drop_table :processing_rule_schedulings
    end
  end
end
