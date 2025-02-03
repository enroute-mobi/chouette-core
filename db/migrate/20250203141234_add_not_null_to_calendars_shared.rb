# frozen_string_literal: true

class AddNotNullToCalendarsShared < ActiveRecord::Migration[5.2]
  def up
    on_public_schema_only do
      change_column :calendars, :shared, :boolean, null: false, default: false
    end
  end

  def down
    on_public_schema_only do
      change_column :calendars, :shared, :boolean, default: false
    end
  end
end
