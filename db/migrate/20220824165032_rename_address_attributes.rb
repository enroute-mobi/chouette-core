class RenameAddressAttributes < ActiveRecord::Migration[5.2]
  def change
    on_public_schema_only do
      rename_column :entrances, :address, :address_line_1 # rubocop:disable Naming/VariableNumber
      rename_column :point_of_interests, :address, :address_line_1 # rubocop:disable Naming/VariableNumber
    end
  end
end
