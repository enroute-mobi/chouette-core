# frozen_string_literal: true

class AddFreezeDataColumnsToReferentials < ActiveRecord::Migration[7.1]
  def change
    on_public_schema_only do
      change_table :referentials do |t|
        t.string :data_freeze_status, null: false, default: 'unfrozen'
      end
    end
  end
end
