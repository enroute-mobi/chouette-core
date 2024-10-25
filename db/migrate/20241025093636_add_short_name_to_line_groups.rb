class AddShortNameToLineGroups < ActiveRecord::Migration[5.2]
  def change
    on_public_schema_only do
      add_column :line_groups, :short_name, :string
    end
  end
end