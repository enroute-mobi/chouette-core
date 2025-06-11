# frozen_string_literal: true

class AddConcurrentTargetToDelayedJobs < ActiveRecord::Migration[6.1]
  def change
    on_public_schema_only do
      change_table :delayed_jobs do |t|
        t.string :concurrent_target, index: true
      end
    end
  end
end
