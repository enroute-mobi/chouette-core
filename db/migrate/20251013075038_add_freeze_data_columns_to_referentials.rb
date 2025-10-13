# frozen_string_literal: true

class AddFreezeDataColumnsToReferentials < ActiveRecord::Migration[7.1]
  def change
    on_public_schema_only do
      change_table :referentials do |t|
        t.datetime :data_frozen_at
        t.boolean :data_freeze_working, null: false, default: false
      end
    end
  end
end
