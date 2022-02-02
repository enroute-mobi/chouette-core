class AddUniquenessConstraintToTimeTablePeriod < ActiveRecord::Migration[5.2]
  def change
    add_index :time_table_periods, [:period_start, :period_end, :time_table_id], :unique => true, name: 'uniq_period_start_and_period_end_per_time_table'
  end
end
