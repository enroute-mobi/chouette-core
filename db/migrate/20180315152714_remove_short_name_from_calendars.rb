class RemoveShortNameFromCalendars < ActiveRecord::Migration
  def change
    remove_column :calendars, :short_name, :string
  end
end
