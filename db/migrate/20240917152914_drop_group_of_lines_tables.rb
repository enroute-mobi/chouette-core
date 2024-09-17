class DropGroupOfLinesTables < ActiveRecord::Migration[5.2]
  def change
    on_public_schema_only do
      drop_table :group_of_lines_lines, if_exists: true
      drop_table :group_of_lines, if_exists: true
    end
  end
end
