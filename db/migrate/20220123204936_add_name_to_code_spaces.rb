class AddNameToCodeSpaces < ActiveRecord::Migration[5.2]
  def change
    on_public_schema_only do
      add_column :code_spaces, :name, :string
    end
  end
end
