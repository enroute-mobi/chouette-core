class AddAllowMultipleValuesToCodeSpaces < ActiveRecord::Migration[5.2]
  def change
    on_public_schema_only do
      add_column :code_spaces, :allow_multiple_values, :boolean, null: false, default: true
    end
  end
end
