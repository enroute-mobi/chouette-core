class AddMaximumDataAgeToWorkgroups < ActiveRecord::Migration[5.2]
  def change
    add_column :workgroups, :maximum_data_age, :integer
  end
end
