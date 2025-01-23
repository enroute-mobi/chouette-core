# frozen_string_literal: true

class AddUuidToLineGroupsAndStopAreaGroups < ActiveRecord::Migration[5.2]
  def change
    on_public_schema_only do
      add_column :line_groups, :uuid, :uuid, default: 'gen_random_uuid()', null: false

      add_column :stop_area_groups, :uuid, :uuid, default: 'gen_random_uuid()', null: false
    end
  end
end
