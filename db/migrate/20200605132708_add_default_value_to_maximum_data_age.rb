class AddDefaultValueToMaximumDataAge < ActiveRecord::Migration[5.2]
  def change
  	change_column :workgroups, :maximum_data_age, :integer, default: 0
  end
end
