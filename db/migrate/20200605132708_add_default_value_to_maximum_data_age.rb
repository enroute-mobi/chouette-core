class AddDefaultValueToMaximumDataAge < ActiveRecord::Migration[5.2]
  def change
    on_public_schema_only do
      change_column :workgroups, :maximum_data_age, :integer, default: 0
    end
  end
end
