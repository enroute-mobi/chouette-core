class AddMaximumDataAgeToWorkgroups < ActiveRecord::Migration[5.2]
  def change
    on_public_schema_only do
      add_column :workgroups, :maximum_data_age, :integer
    end
  end
end
