# frozen_string_literal: true

class AddNotNullToWorkgroupMaximumDataAge < ActiveRecord::Migration[7.1]
  def up
    on_public_schema_only do
      change_column :workgroups, :maximum_data_age, :integer, null: false, default: 0
    end
  end

  def down
    on_public_schema_only do
      change_column :workgroups, :maximum_data_age, :integer, default: 0
    end
  end
end
