class AddUniquenessConstraintToTimeTableDate < ActiveRecord::Migration[5.2]
  def change
    add_index :time_table_dates, [:date, :time_table_id], :unique => true, name: 'uniq_date_per_time_table'
  end
end
