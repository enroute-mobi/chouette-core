class AddColumnsToEntrances < ActiveRecord::Migration[5.2]
  def change
    on_public_schema_only do
      add_column :entrances, :registration_number, :string
      add_column :entrances, :external_flag, :bool
      add_column :entrances, :width, :float
      add_column :entrances, :height, :float
    end
  end
end
