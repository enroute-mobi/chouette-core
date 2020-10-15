class RemovePositionNotNullConstraint < ActiveRecord::Migration[5.2]
  def change
    change_column_null :time_table_dates, :position, true
    change_column_null :time_table_periods, :position, true
  end
end
