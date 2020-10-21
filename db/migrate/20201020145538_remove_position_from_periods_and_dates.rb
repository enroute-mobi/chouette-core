class RemovePositionFromPeriodsAndDates < ActiveRecord::Migration[5.2]
  def change
    remove_column :time_table_dates, :position, :integer
    remove_column :time_table_periods, :position, :integer
  end
end
