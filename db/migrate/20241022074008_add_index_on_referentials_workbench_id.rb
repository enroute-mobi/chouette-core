# frozen_string_literal: true

class AddIndexOnReferentialsWorkbenchId < ActiveRecord::Migration[5.2]
  def change
    on_public_schema_only do
      change_table :referentials do |t|
        t.index :workbench_id
      end
    end
  end
end
